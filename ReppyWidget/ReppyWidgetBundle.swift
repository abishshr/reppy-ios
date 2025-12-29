import SwiftUI
import WidgetKit

@main
struct ReppyWidgetBundle: WidgetBundle {
    var body: some Widget {
        CaloriesWidget()
        MacrosWidget()
        DailySummaryWidget()
    }
}
