import SwiftUI
import ColorJourney

struct ContentView: View {
    let journeys: [(String, [ColorJourneyRGB])] = [
        ("Sunset to Ocean", generateJourney(
            anchor: ColorJourneyRGB(red: 0.95, green: 0.45, blue: 0.3),
            style: .vividLoop,
            count: 12
        )),
        ("Cool Breeze", generateJourney(
            anchor: ColorJourneyRGB(red: 0.2, green: 0.7, blue: 0.85),
            style: .coolSky,
            count: 12
        )),
        ("Warm Glow", generateJourney(
            anchor: ColorJourneyRGB(red: 0.95, green: 0.55, blue: 0.4),
            style: .pastelDrift,
            count: 8
        ))
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                ForEach(journeys, id: \.0) { journey in
                    JourneySwatchView(title: journey.0, colors: journey.1)
                }
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.1))
    }
}

struct JourneySwatchView: View {
    let title: String
    let colors: [ColorJourneyRGB]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Discrete Swatches")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Individually generated colors from the journey.")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            // Swatches grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: min(10, colors.count))
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(
                            red: Double(color.red),
                            green: Double(color.green),
                            blue: Double(color.blue)
                        ))
                        .frame(height: 110)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.15))
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
        )
    }
}

// Helper function to generate a journey
func generateJourney(anchor: ColorJourneyRGB, style: JourneyStyle, count: Int) -> [ColorJourneyRGB] {
    let config = ColorJourneyConfig.singleAnchor(anchor, style: style)
    let journey = ColorJourney(config: config)
    return journey.discrete(count: count)
}

#Preview {
    ContentView()
        .frame(width: 1400, height: 900)
}
