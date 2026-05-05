// TrendChartView.swift
import Charts
import SwiftUI

struct TrendChartView: View {
    let points: [HomeTrendPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tendance")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(OpsCrystal.textPrimary)
                    Text("Mouvements des 7 derniers jours")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(OpsCrystal.textSecondary)
                }

                Spacer()

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(OpsCrystal.accentSecondary)
                    .accessibilityLabel("Graphique tendance")
            }

            Chart(points) { point in
                AreaMark(
                    x: .value("Jour", point.day),
                    y: .value("Valeur", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [OpsCrystal.accentSecondary.opacity(0.30), OpsCrystal.accentSecondary.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Jour", point.day),
                    y: .value("Valeur", point.value)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .foregroundStyle(OpsCrystal.accentSecondary)

                PointMark(
                    x: .value("Jour", point.day),
                    y: .value("Valeur", point.value)
                )
                .symbolSize(42)
                .foregroundStyle(OpsCrystal.textPrimary)
                .annotation(position: .top, alignment: .center) {
                    Text("\(point.value)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(OpsCrystal.textSecondary)
                }
                .shadow(color: OpsCrystal.accentSecondary.opacity(0.8), radius: 6, x: 0, y: 0)
            }
            .frame(height: 190)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let day = value.as(String.self) {
                            Text(day)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(OpsCrystal.textSecondary)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .chartPlotStyle { plotArea in
                plotArea.background(Color.clear)
            }
            .chartYScale(domain: 0...(max(6, (points.map(\.value).max() ?? 0) + 2)))
            .overlay {
                GeometryReader { geo in
                    VStack(spacing: geo.size.height / 4) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(OpsCrystal.border)
                                .frame(height: 1)
                                .overlay {
                                    Rectangle()
                                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                        .foregroundStyle(OpsCrystal.border.opacity(0.85))
                                }
                        }
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(OpsCrystal.surface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(OpsCrystal.border, lineWidth: 1)
        }
    }
}
