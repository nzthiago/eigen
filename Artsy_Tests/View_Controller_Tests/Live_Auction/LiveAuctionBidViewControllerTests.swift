import Quick
import Nimble
import Nimble_Snapshots
import Interstellar
import UIKit

@testable
import Artsy

class LiveAuctionPlaceMaxBidViewControllerSpecs: QuickSpec {
    override func spec() {
        var subject: LiveAuctionPlaceMaxBidViewController!

        beforeEach {
            OHHTTPStubs.stubJSONResponseForHost("metaphysics*.artsy.net", withResponse: [:])
        }

        it("looks right on phones") {
            let devices: [ARDeviceType] = [.Phone4, .Phone6]
            for device in devices {
                ARTestContext.useDevice(device) {
                    subject = StoryboardScene.LiveAuctions.instantiateBid()

                    let fakeSalesPerson = stub_auctionSalesPerson()
                    let lotVM = fakeSalesPerson.lotViewModelForIndex(0)

                    cacheColoredImageForURL(lotVM.urlForProfile)
                    subject.bidViewModel = LiveAuctionBidViewModel(lotVM: lotVM, salesPerson: fakeSalesPerson)

                    expect(subject).to (haveValidSnapshot(named: "bidding_on_\(device.rawValue)", usesDrawRect: true))

                }
            }
        }

        describe("updating") {
            var lotVM: Test_LiveAuctionLotViewModel!
            var salesPerson: Stub_LiveAuctionsSalesPerson!

            beforeEach {
                subject = StoryboardScene.LiveAuctions.instantiateBid()
                lotVM = Test_LiveAuctionLotViewModel()
                salesPerson = stub_auctionSalesPerson()
                subject.bidViewModel = LiveAuctionBidViewModel(lotVM: lotVM, salesPerson: salesPerson)
                subject.loadViewProgrammatically()
            }

            it("updates when new events come in") {
                expect(subject.priceOfCurrentBidsLabel.text) == "$Value"

                salesPerson.currentLotValueString = "£200"
                lotVM.newEventsSignal.update([])

                expect(subject.priceOfCurrentBidsLabel.text) == "£200"
            }

            it("ensures the bid is moved above the current max bid") {

                expect(subject.bidViewModel.currentBid) == 5_500_00

                salesPerson.currentLotValue = 6_000_00
                lotVM.newEventsSignal.update([])

                expect(subject.bidViewModel.currentBid) == 6_000_00
            }
        }

        it("hides the progressview after recieving a lot event after the progress has shown") {
            subject = StoryboardScene.LiveAuctions.instantiateBid()
            let lotVM = Test_LiveAuctionLotViewModel()
            subject.bidViewModel = LiveAuctionBidViewModel(lotVM: lotVM, salesPerson:  stub_auctionSalesPerson())
            subject.loadViewProgrammatically()

            subject.biddingProgressSignal.update(.BiddingInProgress)

            expect(subject.bidProgressOverlayView.superview) != nil

            subject.bidViewModel.lotViewModel.newEventsSignal.update([])
            expect(subject.bidProgressOverlayView.superview).to( beNil() )
        }

        describe("networking") {

            let examples: [String: [LiveAuctionBiddingProgressState]] = [
                "in progress": [.BiddingInProgress],
                "is max bidder": [.BidBecameMaxBidder],
                "not max bidder": [.BidOutbid],
                "network issues": [.BidNetworkFail],
                "waiting": [.LotWaitingToOpen],
                "sold": [.LotSold],
            ]

            for (_, tuple) in examples.enumerate() {

                it("has valid snapshot \(tuple.0)") {
                    subject = StoryboardScene.LiveAuctions.instantiateBid()
                    let lotVM = Test_LiveAuctionLotViewModel()
                    subject.bidViewModel = LiveAuctionBidViewModel(lotVM: lotVM, salesPerson: stub_auctionSalesPerson())
                    cacheColoredImageForURL(lotVM.urlForProfile)
                    subject.loadViewProgrammatically()

                    tuple.1.forEach { subject.biddingProgressSignal.update($0) }

                    expect(subject).to (haveValidSnapshot(named: nil, usesDrawRect: true))
                }
            }
        }
    }
}
