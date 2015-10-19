//
//  HTTPRequest.swift
//  duress
//
//  Created by Cirrena on 7/1/15.
//  Copyright (c) 2015 Cirrena Pty Ltd. All rights reserved.
//

import UIKit


class HTTPRequest : NSObject , NSURLSessionDelegate{
    var mySession : NSURLSession!
    
    private static let timeOutInterval : NSTimeInterval = 30.0
    private static let allowCellularAccess = true
    
    
    init(session : NSURLSession!){
        mySession = session
    }
    convenience override init(){
        let theSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        self.init(session : theSession)
    }
    
    private func send(urlRequest urlRequest : NSMutableURLRequest!, successCompletionHandler : successCompletionBlock, failedCompletionHandler : failedCompletionBlock,  returnData : NSObject.Type?, returnParameters : NSDictionary?){

        let myTask : NSURLSessionDataTask =  mySession.dataTaskWithRequest(urlRequest, completionHandler: {(myData : NSData?, myResponse :  NSURLResponse?, myError : NSError?) -> Void in
            if let returnedData = myData{
                dispatch_async(dispatch_get_main_queue(), {
                    //let newStr = NSString(data: returnedData, encoding: NSUTF8StringEncoding)
                    do {
                        let jsonObject : AnyObject?  = try NSJSONSerialization.JSONObjectWithData(returnedData, options: NSJSONReadingOptions.MutableContainers)
                        if let jsonDictionary  = jsonObject as? NSDictionary {
                            let instance = returnData!.init()
                            if let object = instance as? ThreatProtectModelData {
                                if returnParameters != nil {
                                    object.returnParams = returnParameters
                                }
                                object.parse(jsonDictionary)
                                
                                successCompletionHandler(result: object)
                            }
                        }else{
                            //JSON is empty
                            
                        }
                    } catch let parseError as NSError {
                        //error
                        Flurry.logError("HTTPRequestError", message: "failedCompletionHandler", error: parseError)
                        failedCompletionHandler(result : nil)
                        
                    } catch {
                        fatalError()
                    }
                })
            }
            
        })
        myTask.resume()
    }
    deinit{
        print("\(self) deinit")
        print("\(self.mySession) deinit")
        
        self.mySession.finishTasksAndInvalidate()
        
    }
    
    
    // MARK:
    // MARK: Create Service
    // MARK:
    class func send(httpMethod : String="POST")(returnParameters : NSDictionary?,urlRequest : NSMutableURLRequest!,returnData : NSObject.Type?,successCompletionHandler : successCompletionBlock , failedCompletionHandler : failedCompletionBlock){
        let myService : HTTPRequest  =  HTTPRequest()
        urlRequest.HTTPMethod = httpMethod
        
        myService.send(urlRequest: urlRequest, successCompletionHandler: successCompletionHandler, failedCompletionHandler: failedCompletionHandler, returnData: returnData, returnParameters: returnParameters)
    }
    
    
    static var Post = HTTPRequest.send()
    static var Get = HTTPRequest.send("GET")
    
    // MARK:
    // MARK: Create Request
    // MARK:
    class func configRequest(url url : NSURL!, httpHeaders : NSDictionary? , jsonDictionary : AnyObject? , postBody : NSDictionary?)->NSMutableURLRequest{
        let urlRequest = NSMutableURLRequest(URL: url!)
        
        urlRequest.timeoutInterval = timeOutInterval
        urlRequest.allowsCellularAccess = allowCellularAccess
        
       
        
        if let myHeaders = httpHeaders {
            for (key , value) in myHeaders {
                print("\(key) \(value)")
                urlRequest.setValue(value as? String, forHTTPHeaderField: (key as? String)!)
            }
        }
        
        if let myPostBody = postBody {
            var postString : String?
            for (key , value) in myPostBody {
                print("\(key) \(value)")
                let result : String = "\(key)=\(value)"
                if postString == nil {
                    postString = result
                }else{
                    postString =  postString! + "&" + result
                }
                
            }
            if postString != nil{
                urlRequest.HTTPBody = postString?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
                
                Flurry.logEvent("HTTPRequestEventPostBody", withParameters: postBody! as! [NSObject : AnyObject], timed: true)
            }
        }
        
        
        if let myJson: AnyObject = jsonDictionary {
            
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("gzip", forHTTPHeaderField:"Content-Encoding")
            urlRequest.setValue("gzip", forHTTPHeaderField:"Accept-Encoding")
            
            var myJsonError : NSError?
            
            let myJSONData : NSData?
            do {
                myJSONData = try NSJSONSerialization.dataWithJSONObject(myJson, options: NSJSONWritingOptions.PrettyPrinted)
            } catch let error as NSError {
                myJsonError = error
                myJSONData = nil
                print("\(myJsonError)")
            }
            urlRequest.HTTPBody = myJSONData
            
            Flurry.logEvent("HTTPRequestEventJsonDictionary", withParameters: jsonDictionary! as! [NSObject : AnyObject], timed: true)
        }
        
        return urlRequest
    }
    
    
    
    class func getDataFromUrl(urL:NSURL, completion: downloadImageCompletionBlock) {
        NSURLSession.sharedSession().dataTaskWithURL(urL) { (data, response, error) in
            completion(data: data)
            }.resume()
    }
}