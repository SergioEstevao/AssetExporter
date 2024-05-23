import Foundation
import AVFoundation

class AssetExporterResourceLoaderDelegate : NSObject, AVAssetResourceLoaderDelegate {
    let userAgent: String
    var pendingLoadingRequest = [AVAssetResourceLoadingRequest]()
    var mediaData: Data
    var error: Error?
    var session: URLSession?
    var response: HTTPURLResponse?
    var downloadFinished = false

    init(userAgent: String) {
        self.userAgent = userAgent
        self.mediaData = Data()
    }

    func handleLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest) {
        if let contentInformationRequest = loadingRequest.contentInformationRequest, let response = self.response {
            contentInformationRequest.isByteRangeAccessSupported = true
            contentInformationRequest.contentType = response.value(forHTTPHeaderField:"Content-Type")
            if let contentLength = response.value(forHTTPHeaderField:"Content-Length"),  let intLength = Int64(contentLength) {
                contentInformationRequest.contentLength = intLength
            }
            else {
                contentInformationRequest.contentLength = response.expectedContentLength
            }
        }

        guard let dataRequest = loadingRequest.dataRequest else {
            return
        }

        if loadingRequest.contentInformationRequest != nil && self.response != nil {
            loadingRequest.finishLoading()
            return
        }

        let downloadedData = self.mediaData
        let downloadedDataLength = Int64(downloadedData.count)

        let requestRequestedOffset = dataRequest.requestedOffset
        let requestRequestedLength = Int64(dataRequest.requestedLength)
        let requestCurrentOffset = dataRequest.currentOffset

        if downloadedDataLength < requestCurrentOffset {
            return
        }

        let downloadedUnreadDataLength = downloadedDataLength - requestCurrentOffset
        let requestUnreadDataLength = requestRequestedOffset + requestRequestedLength - requestCurrentOffset
        let respondDataLength = min(requestUnreadDataLength, downloadedUnreadDataLength)

        dataRequest.respond(with: mediaData[requestCurrentOffset..<(requestCurrentOffset+respondDataLength)])

        let requestEndOffset = requestRequestedOffset + requestRequestedLength

        let isFinished = requestCurrentOffset >= requestEndOffset

        if isFinished {
            loadingRequest.finishLoading()
        }

        return
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        print(loadingRequest)
        // handle requests from the player, turn around and make an HTTP call ourself if we have not already fetched it
        // then send the data back to the player
        guard let url = loadingRequest.request.url else {
            return false
        }

        pendingLoadingRequest.append(loadingRequest)

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.scheme = "https"
        let realURL = components.url!

        startDownloadIfNeeded(url: realURL, userAgent: userAgent)
        updateLoadingRequests()
        return true
    }

    func startDownloadIfNeeded(url: URL, userAgent: String) {
        print("fetch \(url)")
        guard session == nil else {
            return
        }
        let config = URLSessionConfiguration.default
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        session = URLSession(configuration: config, delegate: self, delegateQueue: operationQueue)

        var urlRequest = URLRequest(url: url)
        urlRequest.addValue(userAgent, forHTTPHeaderField: "User-Agent") // finally, setting the custom User-Agent!

        guard let session else {
            return
        }
        let task = session.dataTask(with: urlRequest)
        task.delegate = self
        task.resume()
    }

    func updateLoadingRequests() {
        for loadingRequest in pendingLoadingRequest {
            handleLoadingRequest(loadingRequest)
        }
    }
}

extension AssetExporterResourceLoaderDelegate: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.allow)
            return
        }

        self.response = httpResponse

        updateLoadingRequests()

        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let error {
            print(error)
            self.error = error
        } else {
            saveData(mediaData, from: task.currentRequest?.url ?? URL(string:"file.mp3")!)
        }
        downloadFinished = true
        updateLoadingRequests()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        mediaData.append(data)
        updateLoadingRequests()
    }

    func saveData(_ data: Data, from url: URL) {
        let fileName = url.lastPathComponent
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let outputURL = documentsDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
            } catch let error {
                print("Failed to delete file with error: \(error)")
            }
        }

        try? data.write(to: outputURL)
        print("Saved file to:\(outputURL)")
    }
}
