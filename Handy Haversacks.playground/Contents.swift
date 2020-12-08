/*
 --- Day 7: Handy Haversacks ---

 You land at the regional airport in time for your next flight. In fact, it looks like you'll even have time to grab some food: all flights are currently delayed due to issues in luggage processing.

 Due to recent aviation regulations, many rules (your puzzle input) are being enforced about bags and their contents; bags must be color-coded and must contain specific quantities of other color-coded bags. Apparently, nobody responsible for these regulations considered how long they would take to enforce!

 For example, consider the following rules:

 light red bags contain 1 bright white bag, 2 muted yellow bags.
 dark orange bags contain 3 bright white bags, 4 muted yellow bags.
 bright white bags contain 1 shiny gold bag.
 muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
 shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
 dark olive bags contain 3 faded blue bags, 4 dotted black bags.
 vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
 faded blue bags contain no other bags.
 dotted black bags contain no other bags.
 These rules specify the required contents for 9 bag types. In this example, every faded blue bag is empty, every vibrant plum bag contains 11 bags (5 faded blue and 6 dotted black), and so on.

 You have a shiny gold bag. If you wanted to carry it in at least one other bag, how many different bag colors would be valid for the outermost bag? (In other words: how many colors can, eventually, contain at least one shiny gold bag?)

 In the above rules, the following options would be available to you:

 A bright white bag, which can hold your shiny gold bag directly.
 A muted yellow bag, which can hold your shiny gold bag directly, plus some other bags.
 A dark orange bag, which can hold bright white and muted yellow bags, either of which could then hold your shiny gold bag.
 A light red bag, which can hold bright white and muted yellow bags, either of which could then hold your shiny gold bag.
 So, in this example, the number of bag colors that can eventually contain at least one shiny gold bag is 4.

 How many bag colors can eventually contain at least one shiny gold bag? (The list of rules is quite long; make sure you get all of it.)
 
 
 */

import Foundation

let file = Bundle.main.url(forResource: "input", withExtension: "txt")
let rawText = try String(contentsOf: file!, encoding: .utf8)
let list = rawText.lines

let testInput = """
light red bags contain 1 bright white bag, 2 muted yellow bags.
dark orange bags contain 3 bright white bags, 4 muted yellow bags.
bright white bags contain 1 shiny gold bag.
muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
dark olive bags contain 3 faded blue bags, 4 dotted black bags.
vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
faded blue bags contain no other bags.
dotted black bags contain no other bags.
"""

extension String {
    var lines: [String] { components(separatedBy: .newlines) }
}

protocol Bag: CustomStringConvertible {
    var descriptor: String { get set }
    var color: String { get set }
    
    func isEqualTo(other: Bag) -> Bool
}

extension Bag {
    func isEqualTo(other: Bag) -> Bool {
        return (self.descriptor == other.descriptor) && (self.color == other.color)
    }
}

struct OuterBag: Bag, Hashable {
    
    var descriptor: String
    var color: String
    var bags: [InnerBag]
    
    var description: String {
        return "\(descriptor) \(color) bag"
    }
    
    init(descriptor: String, color: String, bags: [InnerBag] = []) {
        self.descriptor = descriptor
        self.color = color
        self.bags = bags
    }
    
    init?(_ input: String) {
        if input == "" {
            return nil
        }
        
        let seperatedBags = input.components(separatedBy: "contain")
        let bagString = seperatedBags[0].components(separatedBy: .whitespaces)
        let subBagsString = seperatedBags[1].components(separatedBy: ",")
        
        self.descriptor = bagString[0]
        self.color = bagString[1]
        self.bags = subBagsString.compactMap { InnerBag($0) }
        
        if bags.isEmpty {
            return nil
        }
    }
    
    func contains<T: Bag>(_ bag: T) -> Bool {
        for item in self.bags {
            if item.isEqualTo(other: bag) {
                return true
            }
        }
        return false
    }
    
    func bagsContained() -> [(bag: OuterBag, number: Int)] {
        return bags.map { (OuterBag(descriptor: $0.descriptor, color: $0.color), $0.quantity)}
    }
    
    static func == (lhs: OuterBag, rhs: OuterBag) -> Bool {
        return lhs.isEqualTo(other: rhs)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(descriptor)
        hasher.combine(color)
    }
}

struct InnerBag: Bag {
    
    var descriptor: String
    var color: String
    var quantity: Int
    
    var description: String {
        return "\(quantity) \(descriptor) \(color) bag\(quantity > 1 ? "s" : "")"
    }
    
    init(descriptor: String, color: String, quantity: Int) {
        self.descriptor = descriptor
        self.color = color
        self.quantity = quantity
    }
    
    init?(_ innerBag: String) {
        let seperated = innerBag.components(separatedBy: .whitespaces)
        guard let num = Int(seperated[1]) else { return nil }
        self.quantity = num
        self.descriptor = seperated[2]
        self.color = seperated[3]
    }
    
}

extension Array where Element == InnerBag {
    var description: String {
        let bagsStrings = self.map { $0.description }
        let output = bagsStrings.joined(separator: ", ")
        return "\(output)."
    }
}

extension Array where Element == OuterBag {
    subscript(bag: OuterBag) -> OuterBag? {
        return self.first(where: { $0 == bag })
    }
}

struct BagRules {
    var bags: [OuterBag]
    
    init(_ strings: [String]) {
        self.bags = strings.compactMap { OuterBag($0) }
    }
    
    func find(_ bags: Set<OuterBag>, foundBags: Set<OuterBag> = []) -> Int {
        print(#function, foundBags.count)
        var newBags: Set<OuterBag> = []
        
        for bag in bags {
            let contents = Set(self.bags.filter { $0.contains(bag) })
            newBags.formUnion(contents)
        }
        
        return newBags.isEmpty ? foundBags.count : find(newBags, foundBags: foundBags.union(newBags))
    }
    
    func numberOfBags(with bags: [(bag: OuterBag, number: Int)], runningTotal: Int = 0) -> Int {
        var total = 0
        
        for item in bags {
            if let foundBag = self.bags[item.bag] {
                let containedBags = foundBag.bagsContained()
                for item in containedBags {
                    total += numberOfBags(with: [item]) * item.number
                }
                var quantitiyInBag = 0
                for item in containedBags {
                    quantitiyInBag += item.number
                }
                total += quantitiyInBag
            }
        }
        
        return total
    }
}

func test() {
    let list = testInput.lines
    let rules = BagRules(list)
    let bag = OuterBag(descriptor: "shiny", color: "gold")
    
    let shinyGoldBags = rules.find([bag])
    print(shinyGoldBags)
}

//test()

func answerToPartOne() {
    let rules = BagRules(list)
    let bag = OuterBag(descriptor: "shiny", color: "gold")
    
    let shinyGoldBags = rules.find([bag])
    print(shinyGoldBags)
}

//answerToPartOne()

func test2() {
    let list = testInput.lines
    let rules = BagRules(list)
    let bag = OuterBag(descriptor: "shiny", color: "gold")
    
    let bags = rules.numberOfBags(with: [(bag, 1)])
    print(bags)
}

func answerToPartTwo() {
    let rules = BagRules(list)
    let bag = OuterBag(descriptor: "shiny", color: "gold")
    
    let bags = rules.numberOfBags(with: [(bag, 1)])
    print(bags)
}

test2()
answerToPartTwo()
