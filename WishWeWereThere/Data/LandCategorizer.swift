//
//  LandCategorizer.swift
//  Wish We Were There
//

import Foundation

private struct LandRule {
    let land: String
    let needles: [String]
}

private let landRules: [String: [LandRule]] = [
    // Magic Kingdom
    "75ea578a-adc8-4116-a54d-dccb60765ef9": [
        LandRule(land: "Main Street, U.S.A.", needles: ["main street", "town square", "vehicles"]),
        LandRule(land: "Adventureland", needles: ["jungle cruise", "pirates", "tiki", "magic carpets", "swiss family", "aladdin"]),
        LandRule(land: "Frontierland", needles: ["big thunder", "tiana", "splash mountain", "country bear", "tom sawyer", "railroad - frontierland"]),
        LandRule(land: "Liberty Square", needles: ["haunted mansion", "hall of presidents", "liberty belle"]),
        LandRule(land: "Fantasyland", needles: [
            "seven dwarfs", "small world", "peter pan", "dumbo", "little mermaid", "under the sea",
            "winnie the pooh", "mad tea", "philharmagic", "barnstormer", "enchanted tales",
            "prince charming", "carrousel", "casey jr", "railroad - fantasyland", "princess fairytale",
        ]),
        LandRule(land: "Tomorrowland", needles: [
            "space mountain", "buzz lightyear", "tron", "peoplemover", "astro orbiter", "speedway",
            "laugh floor", "carousel of progress", "tomorrowland",
        ]),
    ],
    // EPCOT
    "47f90d2c-e191-4239-a466-5892ef59a88b": [
        LandRule(land: "World Celebration", needles: ["spaceship earth", "figment", "imagination", "short film", "dreamers point"]),
        LandRule(land: "World Nature", needles: ["soarin", "living with the land", "seas with nemo", "turtle talk", "journey of water", "awesome planet"]),
        LandRule(land: "World Discovery", needles: ["guardians", "cosmic rewind", "test track", "mission: space", "mission space"]),
        LandRule(land: "World Showcase", needles: [
            "frozen", "ratatouille", "remy", "gran fiesta", "canada", "impressions de france",
            "american adventure", "reflections of china", "beauty and the beast sing", "japan",
            "morocco", "germany", "italy", "united kingdom", "norway", "mexico", "france",
        ]),
    ],
    // Hollywood Studios
    "288747d1-8b4f-4a64-867e-ea7c9b27bad8": [
        LandRule(land: "Hollywood Boulevard", needles: ["runaway railway", "mickey & minnie"]),
        LandRule(land: "Echo Lake", needles: ["star tours", "indiana jones", "frozen sing", "vacation fun"]),
        LandRule(land: "Grand Avenue", needles: ["muppet"]),
        LandRule(land: "Toy Story Land", needles: ["slinky", "toy story mania", "alien swirling"]),
        LandRule(land: "Star Wars: Galaxy's Edge", needles: ["rise of the resistance", "millennium falcon", "smugglers run"]),
        LandRule(land: "Sunset Boulevard", needles: ["tower of terror", "rock", "roller coaster", "beauty and the beast live", "fantasmic"]),
        LandRule(land: "Animation Courtyard", needles: ["walt disney presents", "voyage of the little mermaid", "animation"]),
    ],
    // Animal Kingdom
    "1c84a229-8862-4648-9c71-378ddd2c7693": [
        LandRule(land: "Pandora", needles: ["flight of passage", "navi river", "na'vi"]),
        LandRule(land: "Africa", needles: ["kilimanjaro", "festival of the lion king", "gorilla falls", "wildlife"]),
        LandRule(land: "Asia", needles: ["expedition everest", "kali river", "maharajah", "feathered friends"]),
        LandRule(land: "DinoLand U.S.A.", needles: ["dinosaur", "triceratop", "finding nemo", "dino"]),
        LandRule(land: "Discovery Island", needles: ["tree of life", "tough to be a bug", "discovery island"]),
        LandRule(land: "Rafiki's Planet Watch", needles: ["conservation", "bluey", "rafiki", "wildlife express"]),
    ],
]

private func normalize(_ value: String) -> String {
    let lowered = value.lowercased()
    let stripped = lowered.replacingOccurrences(of: "['\u{2019}\"\u{201c}\u{201d}]", with: "", options: .regularExpression)
    let collapsed = stripped.replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
    return collapsed.trimmingCharacters(in: .whitespaces)
}

func landFor(parkID: String, name: String) -> String {
    let haystack = normalize(name)
    for rule in landRules[parkID] ?? [] {
        if rule.needles.contains(where: { haystack.contains(normalize($0)) }) {
            return rule.land
        }
    }
    return "Parkwide"
}
