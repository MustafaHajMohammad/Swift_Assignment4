import Foundation

protocol IdentifiableContent {
    var title: String { get }
    var sizeMB: Double { get }
    var price: Double { get }
}

protocol DownloadSpeedProviding { var speedMBps: Double { get } }

struct Receipt {
    let items: [any IdentifiableContent]
    let totalPrice: Double
    let estimatedSeconds: Double
    let missing: [String]
}

protocol ContentServing: DownloadSpeedProviding {
    associatedtype Item: IdentifiableContent
    var catalog: [Item] { get }
    func serve(wishList: [String]) -> Receipt
}

extension ContentServing {
    func serve(wishList: [String]) -> Receipt {
        let byTitle = Dictionary(uniqueKeysWithValues: catalog.map { ($0.title, $0) })
        var found: [Item] = []
        var missing: [String] = []

        for title in wishList {
            if let it = byTitle[title] { found.append(it) } else { missing.append(title) }
        }

        let totalSize = found.reduce(0.0) { $0 + $1.sizeMB }
        let totalPrice = found.reduce(0.0) { $0 + $1.price }
        let est = speedMBps > 0 ? totalSize / speedMBps : .infinity

        let rounded = (totalPrice * 100).rounded() / 100.0

        return Receipt(
            items: found.map { $0 as any IdentifiableContent },
            totalPrice: rounded,
            estimatedSeconds: est,
            missing: missing
        )
    }
}

struct Song: IdentifiableContent { let title: String; let sizeMB: Double; let price: Double }
struct Movie: IdentifiableContent { let title: String; let sizeMB: Double; let price: Double }

struct MusicServer: ContentServing {
    let catalog: [Song]
    let speedMBps: Double
}
struct VideoServer: ContentServing {
    let catalog: [Movie]
    let speedMBps: Double
}

struct AnyContentServer {
    private let _serve: ([String]) -> Receipt
    init<S: ContentServing>(_ server: S) { _serve = { server.serve(wishList: $0) } }
    func serve(wishList: [String]) -> Receipt { _serve(wishList) }
}

struct Storefront {
    var server: AnyContentServer
    func checkout(titles: [String]) -> Receipt { server.serve(wishList: titles) }
}

func printReceipt(_ r: Receipt) {
    let itemsList = r.items.map { $0.title }.joined(separator: ", ")
    let missingList = r.missing.joined(separator: ", ")
    let seconds = String(format: "%.2f", r.estimatedSeconds)
    let minutes = String(format: "%.2f", r.estimatedSeconds / 60.0)
    let total = String(format: "%.2f", r.totalPrice)
    print("Items: \(itemsList.isEmpty ? "-" : itemsList)")
    print("Missing: \(missingList.isEmpty ? "None" : missingList)")
    print("Estimated download: \(seconds) s (\(minutes) min)")
    print("Total: $\(total)\n")
}

let songs = [
    Song(title: "Aurora", sizeMB: 5.0, price: 0.99),
    Song(title: "Nebula", sizeMB: 7.5, price: 1.29),
    Song(title: "Quasar", sizeMB: 6.2, price: 1.09)
]

let movies = [
    Movie(title: "Solaris Rising", sizeMB: 900, price: 12.99),
    Movie(title: "Event Horizon Redux", sizeMB: 1500, price: 14.99),
    Movie(title: "Starlight Express", sizeMB: 1100, price: 9.99)
]

let musicServer = MusicServer(catalog: songs, speedMBps: 5)
let videoServer = VideoServer(catalog: movies, speedMBps: 20)

var store = Storefront(server: AnyContentServer(musicServer))

print("Run 1 (Music)")
let r1 = store.checkout(titles: ["Aurora", "Quasar", "Nope"])
printReceipt(r1)

store.server = AnyContentServer(videoServer)

print("Run 2 (Video)")
let r2 = store.checkout(titles: ["Solaris Rising", "Starlight Express"])
printReceipt(r2)
