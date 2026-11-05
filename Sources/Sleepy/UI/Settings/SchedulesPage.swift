import SleepyCore
import SwiftUI

struct SchedulesPage: View {
    @Bindable var model: AppModel
    @State private var editing: Schedule.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageHeader(title: "Schedules", subtitle: "Sleep every night. Pick days, time and duration.") {
                Button {
                    editing = model.store.addSchedule().id
                } label: { Label("New", systemImage: "plus") }
                .buttonStyle(PillButtonStyle(kind: .outline))
            }
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Bindable(model.store).schedules) { $schedule in
                        ScheduleRow(
                            schedule: $schedule,
                            isEditing: editing == schedule.id,
                            onEdit: { editing = editing == schedule.id ? nil : schedule.id },
                            onDelete: { model.store.delete(schedule.id) }
                        )
                        Hairline()
                    }
                }
            }
            .scrollIndicators(.never)
        }
    }
}

private struct ScheduleRow: View {
    @Binding var schedule: Schedule
    let isEditing: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    private static let durations = [15, 30, 45, 60, 90, 120, 150, 180, 240]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: onEdit) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(schedule.name).font(.system(size: 13.5, weight: .medium))
                            Text(schedule.summary).label(Theme.secondary, size: 9)
                            Image(systemName: isEditing ? "chevron.up" : "pencil")
                                .font(.system(size: 9)).foregroundStyle(Theme.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    HStack(spacing: 4) {
                        ForEach(Weekday.allCases, id: \.self) { day in
                            DayChip(day: day, isOn: Binding(
                                get: { schedule.weekdays.contains(day) },
                                set: { on in
                                    if on { schedule.weekdays.insert(day) } else { schedule.weekdays.remove(day) }
                                }
                            ))
                        }
                    }
                }
                Spacer()
                SquareToggle(isOn: $schedule.enabled).padding(.top, 10)
            }
            if isEditing { editor }
        }
        .padding(.vertical, 13)
        .opacity(schedule.enabled ? 1 : 0.85)
    }

    private var editor: some View {
        HStack(spacing: 12) {
            TextField("Name", text: $schedule.name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 140)
            DatePicker("Starts", selection: startTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
            Picker("For", selection: $schedule.durationMinutes) {
                ForEach(Self.durations, id: \.self) { Text(TimeFormat.duration(minutes: $0).lowercased()).tag($0) }
            }
            .labelsHidden()
            .frame(width: 110)
            Spacer()
            Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }
                .buttonStyle(.borderless)
                .accessibilityLabel("Delete schedule")
        }
        .controlSize(.small)
    }

    private var startTime: Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: schedule.hour, minute: schedule.minute, second: 0, of: Date())! },
            set: { d in
                let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                schedule.hour = c.hour ?? 0
                schedule.minute = c.minute ?? 0
            }
        )
    }
}

private struct DayChip: View {
    let day: Weekday
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            Text(day.letter)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .frame(width: 20, height: 20)
                .foregroundStyle(isOn ? Color.white : Theme.secondary)
                .background {
                    if isOn { Rectangle().fill(Theme.accent) }
                    else { Rectangle().strokeBorder(Color.white.opacity(0.3), lineWidth: 0.75) }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.shortName)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}
