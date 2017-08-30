//
//  Response+Serializable.swift
//
//  Created by Nazih Shoura.
//  Copyright © 2017 Nazih Shoura. All rights reserved.
//  See LICENSE.txt for license information
//

import Foundation
import Alamofire
import RxSwift

extension DataRequest {

    /**
     Serilize the json rescived from the network to the object represented by the function genaric type.
     The genaric type must comfirm to Serializable Protocol

     - returns: The serialized object if the serialization was successful. Otherwise, returns an Error.
     */
    public static func ObjectMapperSerializer<T: Serializable>() -> DataResponseSerializer<T> {
        let result: DataResponseSerializer<T> = DataResponseSerializer { request, response, data, error in
            if let error = error {
                return .failure(error)
            }

            let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonResponseSerializer.serializeResponse(request, response, data, error)

            do {
                let parsedObject = try T(jsonRepresentation: result.value)
                return .success(parsedObject)
            } catch {
                return .failure(error)
            }
        }

        return result
    }

    /**
     Adds a handler to be called once the request has finished.

     - parameter queue:             The queue on which the completion handler is dispatched.
     - parameter keyPath:           The key path where object mapping should be performed
     - parameter object:            An object to perform the mapping on to
     - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.

     - returns: The request.
     */
    @discardableResult
    public func responseObject<T: Serializable>(queue: DispatchQueue? = nil, keyPath _: String? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.ObjectMapperSerializer(), completionHandler: completionHandler)
    }
}
