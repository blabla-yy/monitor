//
//  BandwidthMonitorTests.swift
//  BandwidthMonitorTests
//
//  Created by wyy on 2023/7/18.
//  Copyright © 2023 yahaha. All rights reserved.
//

import XCTest

final class BandwidthMonitorTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        let shell = "nettop -t wifi -t wired -k rx_dupe,rx_ooo,re-tx,rtt_avg,rcvsize,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W,interface,state,arch -d -L 0 -P -n"
        let cmd = shell.split(separator: " ").map { String($0) }
        var i = 1
        let process = ProcessHelper.start(arguments: cmd) {
            let content = String(data: $0, encoding: .utf8) ?? ""
            print(content == "time,,bytes_in,bytes_out,".trimmingCharacters(in: .whitespacesAndNewlines))
        }
        XCTAssertTrue(process.isRunning())
        
        Thread.sleep(forTimeInterval: 3)
        process.terminate()
        process.wait()
        XCTAssertTrue(!process.isRunning())
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
