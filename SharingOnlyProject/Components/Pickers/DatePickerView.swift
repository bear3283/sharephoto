import SwiftUI

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var showingDatePicker: Bool
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Text("선택된 날짜")
                .font(.subheadline)
                .fontWeight(.medium)
.foregroundStyle(theme.secondaryGradient)
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingDatePicker.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text(selectedDate, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
.foregroundColor(theme.primaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.98, blue: 0.95),
                                    Color(red: 0.92, green: 0.96, blue: 0.98)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 0.1, green: 0.6, blue: 0.8).opacity(0.1), radius: 3, x: 0, y: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 1.0, blue: 0.95),
                            Color(red: 0.95, green: 0.98, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(red: 0.1, green: 0.7, blue: 0.4).opacity(0.1), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
}

// Overlay Calendar Picker with Natural Animations
struct OverlayDatePicker: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let onDateSelected: () -> Void
    
    @State private var backgroundOpacity: Double = 0.0
    @State private var calendarScale: Double = 0.85
    @State private var calendarOpacity: Double = 0.0
    @State private var calendarOffset: CGFloat = 30
    
    var body: some View {
        ZStack {
            // Enhanced Background Blur with Better Dimming
            LinearGradient(
                colors: [
                    Color.black.opacity(backgroundOpacity * 0.25),
                    Color.black.opacity(backgroundOpacity * 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .onTapGesture {
                dismissCalendar()
            }
            
            // Calendar picker with natural entrance - 고정 크기 적용
            VStack(spacing: 24) {
                HStack {
                    Text("날짜 선택")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Spacer()
                    
                    Button(action: dismissCalendar) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            .scaleEffect(0.9)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // DatePicker를 고정 크기 컨테이너로 감싸기 - GeometryReader로 더 강력한 크기 제약
                GeometryReader { geometry in
                    ZStack {
                        // 고정된 배경 프레임
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.clear)
                            .frame(width: 300, height: 320) // 고정된 크기
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        
                        DatePicker("날짜 선택",
                                  selection: $selectedDate,
                                  displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .colorScheme(.light)
                            .accentColor(Color(red: 0.2, green: 0.7, blue: 0.4))
                            .frame(width: 300, height: 320) // DatePicker도 같은 고정 크기
                            .frame(minWidth: 300, maxWidth: 300, minHeight: 320, maxHeight: 320) // 최소/최대 크기 강제 고정
                            .fixedSize(horizontal: true, vertical: true) // 양방향 고정된 크기 유지
                            .clipped() // 넘치는 부분 잘라내기
                            .animation(.none, value: selectedDate) // 날짜 변경 시 애니메이션 비활성화
                            .layoutPriority(1) // 레이아웃 우선순위 설정
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            .onChange(of: selectedDate) { _, _ in
                                // 날짜 선택 시 콜백만 호출하고 자동으로 닫지 않음
                                onDateSelected()
                            }
                    }
                }
                .frame(width: 300, height: 320) // GeometryReader 자체도 고정 크기
                
                // 완료 버튼 추가
                Button(action: dismissCalendar) {
                    Text("완료")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 1.0, blue: 0.97),
                                Color(red: 0.96, green: 0.99, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.12),
                        radius: 24,
                        x: 0,
                        y: 12
                    )
                    .shadow(
                        color: Color.black.opacity(0.06),
                        radius: 48,
                        x: 0,
                        y: 24
                    )
            )
            .frame(width: 350, height: 480) // 전체 달력 컨테이너 고정 크기
            .frame(minWidth: 350, maxWidth: 350, minHeight: 480, maxHeight: 480) // 최소/최대 크기 강제 고정
            .fixedSize(horizontal: true, vertical: true) // 컨테이너도 고정 크기 유지
            .padding(.horizontal, 24)
            .scaleEffect(calendarScale)
            .opacity(calendarOpacity)
            .offset(y: calendarOffset)
        }
        .onAppear {
            presentCalendar()
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                presentCalendar()
            } else {
                hideCalendar()
            }
        }
    }
    
    private func presentCalendar() {
        // 동시 시작으로 더 자연스러운 등장
        withAnimation(.easeOut(duration: 0.35)) {
            backgroundOpacity = 1.0
        }
        
        // 부드러운 스프링 애니메이션으로 자연스러운 바운스
        withAnimation(.interpolatingSpring(stiffness: 180, damping: 20)) {
            calendarScale = 1.0
            calendarOpacity = 1.0
            calendarOffset = 0
        }
    }
    
    private func hideCalendar() {
        // 대칭적인 타이밍으로 일관성 향상 - 같은 스케일로 유지
        withAnimation(.easeInOut(duration: 0.3)) {
            calendarScale = 0.85  // 등장시와 동일한 크기로 변경
            calendarOpacity = 0.0
            calendarOffset = 30   // 등장시와 동일한 오프셋으로 변경
        }
        
        withAnimation(.easeOut(duration: 0.35)) {
            backgroundOpacity = 0.0
        }
    }
    
    private func dismissCalendar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

#Preview {
    DatePickerView(selectedDate: .constant(Date()), showingDatePicker: .constant(false))
        .padding()
}