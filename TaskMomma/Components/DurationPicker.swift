import SwiftUI

struct DurationPicker: View {
    @Binding var selectedMinutes: Int

    private let options = [2, 5, 10]

    var body: some View {
        Picker("Duration", selection: $selectedMinutes) {
            ForEach(options, id: \.self) { minutes in
                Text("\(minutes) min")
                    .tag(minutes)
            }
        }
        .pickerStyle(.segmented)
    }
}

