//
//  GetChannelListAPI.swift
//
//  Created by Nazih Shoura.
//  Copyright © 2017 Nazih Shoura. All rights reserved.
//  See LICENSE.txt for license information
//

import Foundation
import RxSwift
import Alamofire

protocol GetChannelListAPIType {
    func reponsePayload(forRequestPayload requestPayload: GetChannelListAPI.RequestPayload) -> Observable<GetChannelListAPI.ResponsePayload>
}

struct GetChannelListAPI: GetChannelListAPIType {
    let networkService: NetworkServiceType
    let KeyProvider: KeyProvider

    init(
        networkService: NetworkServiceType = singleInstance.networkService
        , KeyProvider: KeyProvider = singleInstance.keyProvider
    ) {
        self.networkService = networkService
        self.KeyProvider = KeyProvider
    }

    func reponsePayload(forRequestPayload requestPayload: GetChannelListAPI.RequestPayload) -> Observable<GetChannelListAPI.ResponsePayload> {

        let URL = KeyProvider.baseURL.appendingPathComponent("/ams/v3/getChannelList")

        let result = Observable.create { (observer: AnyObserver<GetChannelListAPI.ResponsePayload>) -> Disposable in

            let parameters = requestPayload.deserialize()
            let urlRequest = self.networkService.urlRequestConvertible(
                forURL: URL
                , method: .get
                , parameters: parameters
                , encoding: URLEncoding.default
                , headers: nil
            )

            let request = self.networkService.managerWithDefaultConfiguration.request(urlRequest)

            request.responseObject { (response: DataResponse<GetChannelListAPI.ResponsePayload>) -> Void in
                if let value = response.result.value { observer.on(.next(value)) }
                if let error = response.result.error { observer.on(.error(error)) }
                observer.on(.completed)
            }

            return Disposables.create(with: { request.cancel() })
        }
        return result
    }
}

extension GetChannelListAPI {
    struct RequestPayload: Deserializable {
        func deserialize() -> [String: AnyObject] {
            return [:]
        }
    }

    struct ResponsePayload: Serializable {
        let channels: [Channel]

        init(
            channels: [Channel]
        ) {
            self.channels = channels
        }

        init(jsonRepresentation: Any?) throws {
            guard let json = jsonRepresentation as? [String: Any] else {
                throw SerializationError.serializationFailed(
                    forKeyPath: Channel.subjectLabel
                    , receivedKeyValue: ("channels", jsonRepresentation)
                )
            }

            guard let channelsRepresentations = json["channels"] as? [Any?] else {
                throw SerializationError.serializationFailed(
                    forKeyPath: Channel.subjectLabel
                    , receivedKeyValue: ("channels", jsonRepresentation)
                )
            }

            var channels: [Channel] = []
            for channelRepresentation in channelsRepresentations {
                let channel = try Channel(jsonRepresentation: channelRepresentation)
                channels.append(channel)
            }

            self.init(channels: channels)
        }
    }
}
