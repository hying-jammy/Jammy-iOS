# Jammy (째미) — iOS

친구들과 여행을 기록하고 공유하며, 여행이 끝난 뒤 **타임캡슐을 함께 열어** 서로의 기억을 비교하고 회상하는 앱.

> 여행 중에는 함께 기록하고, 여행 후에는 함께 열어보며 추억한다.

브랜드 콘셉트는 "putting fun into a jar". 딸기잼 레드를 메인으로 하는 밝고 둥근 UI.

## 기술 스택 / 전제

- **UI**: SwiftUI
- **최소 지원**: **iOS 18.0** 이상 (앱 타깃 `IPHONEOS_DEPLOYMENT_TARGET = 18.0`, Xcode 26). `@Observable`, `NavigationStack`, `#Preview` 등 최신 SwiftUI API 를 사용한다.
- **Swift 설정 주의**: 프로젝트가 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_VERSION = 5.0` 이다.
  따라서 타입은 기본적으로 `@MainActor` 이다. 백그라운드 작업이 필요한 순수 타입/함수에만 `nonisolated` 를 명시한다.
- **아키텍처**: MVVM (Observation 프레임워크의 `@Observable` 사용)
- **비동기**: Swift Concurrency (`async/await`, `@MainActor`)
- **네비게이션**: `NavigationStack` + `NavigationPath` (타입 기반 Route)
- **서드파티 라이브러리**: 기본적으로 쓰지 않는다. 필요하면 먼저 사용자에게 확인한다.
- **디자인 기준 기기**: iPhone 13 mini (375×812). 작은 화면에서도 깨지지 않게 만든다.
- **폰트**: Pretendard. 폰트 파일(.ttf)은 `Jammy-iOS/Resources/Fonts/` 에 있고, `Jammy-iOS/Info.plist` 의 `UIAppFonts` 로 시스템이 자동 등록한다.
  - 사용: `.font(.pretendard(.semibold, size: 15))` (`Core/DesignSystem/Fonts/Pretendard.swift`). 값은 PostScript 이름(`Pretendard-SemiBold`)이다.
  - 폰트를 추가하면 `Info.plist` 의 `UIAppFonts` 에도 파일명을 추가해야 한다. 에셋 카탈로그 데이터 에셋으로 넣으면 적용되지 않는다.
  - `Info.plist` 는 `GENERATE_INFOPLIST_FILE = YES` 와 함께 쓰는 보조 파일이다(자동 생성 설정과 병합됨).

### 백엔드 상태 (중요)

**API는 아직 없다. 추후 연결 예정이다.** 따라서 지금은 모든 데이터를 Mock으로 제공하되,
나중에 실제 API로 **ViewModel/View 수정 없이 교체**할 수 있게 구조를 잡는다. (아래 "데이터 계층" 참고)

## 폴더 구조

```
Jammy-iOS/Jammy-iOS/            # Xcode 프로젝트 루트 소스 폴더 (폴더 동기화 방식이라 폴더를 추가하면 자동 포함됨)
├── App/
│   ├── JammyApp.swift            # @main, 의존성 컨테이너 주입
│   ├── AppContainer.swift        # Repository 등 의존성 조립 (mock/live 전환 지점)
│   └── AppRouter.swift           # 앱 전체 라우팅 / 인증 상태에 따른 루트 전환
├── Core/
│   ├── DesignSystem/
│   │   ├── Tokens/               # (추후) Font, Spacing, Radius, Shadow. 색은 Assets.xcassets 사용
│   │   └── Components/           # JammyButton, JammyChip, JammyTextField ...
│   ├── Networking/               # (API 연결 시 추가) APIClient, Endpoint, APIError
│   ├── Storage/                  # Keychain, UserDefaults 래퍼
│   ├── Extensions/
│   └── Utilities/
├── Domain/
│   ├── Models/                   # User, TripRoom, DiaryEntry, TimeCapsule ...
│   └── Repositories/             # Repository 프로토콜 (인터페이스만)
├── Data/
│   ├── Mock/                     # Mock 구현 + 샘플 데이터
│   ├── Remote/                   # (추후) DTO, API 구현체
│   └── Mappers/                  # DTO ↔ Domain 변환
├── Features/
│   ├── Onboarding/               # Welcome(초기 화면)
│   ├── Auth/                     # Login, SignUp
│   ├── Home/                     # 참여 중인 여행 목록
│   ├── Room/                     # CreateRoom, InviteCode, JoinRoom, RoomMain(피드/기록 탭)
│   ├── Diary/                    # WriteDiary
│   └── Capsule/                  # CreateCapsule, CapsuleDetail(공개 전/후)
├── Resources/
│   └── Fonts/                    # Pretendard .ttf (Info.plist UIAppFonts 에 등록)
└── Assets.xcassets/
    ├── Colors/                   # Jammy 색상 컬러 세트 21개 (아래 "색상" 참고)
    ├── AppIcon.appiconset
    └── AccentColor.colorset
```

각 Feature 폴더는 `View` / `ViewModel` / (필요 시) `Components` 로 나눈다.
예: `Features/Room/RoomMain/RoomMainView.swift`, `RoomMainViewModel.swift`

## MVVM 규칙

### 책임 분리

| 계층 | 책임 | 하지 말 것 |
|---|---|---|
| **View** | 화면 그리기, 사용자 입력을 ViewModel에 전달 | 비즈니스 로직, 네트워크 호출, 날짜/상태 계산 |
| **ViewModel** | 화면 상태 보유, 사용자 액션 처리, Repository 호출 | SwiftUI 뷰 타입 import(Color 등 표현 로직 제외), 직접 URLSession 사용 |
| **Repository(프로토콜)** | 데이터 접근 추상화 | UI 의존 |
| **Domain Model** | 앱의 순수 데이터 모델 | DTO/UI 의존 |

### ViewModel 작성 패턴 (Observation)

```swift
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum State { case idle, loading, loaded([TripRoom]), failed(AppError) }

    private(set) var state: State = .idle
    private let roomRepository: RoomRepository

    init(roomRepository: RoomRepository) {
        self.roomRepository = roomRepository
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await roomRepository.fetchMyRooms())
        } catch {
            state = .failed(AppError(error))
        }
    }
}
```

- `ObservableObject` / `@Published` / `@StateObject` / `@ObservedObject` 는 **쓰지 않는다.** (Observation 사용)
- View가 ViewModel을 소유하면 `@State private var viewModel`, 외부에서 받으면 일반 프로퍼티 또는 `@Bindable`.
- ViewModel 은 `@MainActor` + `@Observable` + `final class`.
- 화면 상태는 가능하면 enum 하나(`idle/loading/loaded/failed`)로 표현한다. 불가능한 상태 조합을 만들지 않는다.
- 사용자 액션은 ViewModel 메서드로 노출한다 (`func didTapSave()`, `func load() async`).
- View에서 `.task { await viewModel.load() }` 로 로딩을 시작한다.
- 의존성은 **이니셜라이저 주입**. 싱글톤 직접 접근 금지.

### Preview

- `#Preview` 매크로 사용. 항상 Mock Repository 로 구성한다.
- 로딩/빈 상태/에러 상태 Preview 도 가능하면 함께 만든다.

## 데이터 계층 (API 연결 대비)

핵심: **Repository 프로토콜을 경계로 삼는다.** 지금은 Mock, 나중에 Remote.

```swift
// Domain/Repositories
protocol RoomRepository {
    func fetchMyRooms() async throws -> [TripRoom]
    func createRoom(_ draft: NewRoomDraft) async throws -> TripRoom
    func joinRoom(inviteCode: String) async throws -> TripRoom
}

// Data/Mock
struct MockRoomRepository: RoomRepository { ... }   // 지금 구현

// Data/Remote (추후)
struct RemoteRoomRepository: RoomRepository { ... } // API 연결 시 구현
```

- 의존성 조립은 `AppContainer` 한 곳에서만 한다. Mock ↔ Remote 전환은 여기서만 바뀐다.
- Mock 은 **실제처럼 동작**하게 만든다: `try await Task.sleep` 로 약간의 지연, 실패 케이스(잘못된 초대 코드 등)도 던질 수 있게.
- Mock 데이터는 메모리에 유지해서 "방 만들기 → 홈 목록에 나타남" 같은 흐름이 앱 안에서 이어지게 한다 (Mock 저장소는 `@MainActor` 클래스. 프로젝트가 기본 MainActor 격리라 Sendable 문제를 피하기 위함).
- 서버 응답 모양을 아직 모르므로 **Domain Model 을 먼저 안정적으로 설계**하고, API 연결 시 `DTO → Domain` Mapper 로 흡수한다. Domain Model 에 `Codable` 을 억지로 붙이지 않는다.
- 에러는 `AppError`(Domain 수준)로 통일한다. 네트워크/서버 에러는 Data 계층에서 `AppError` 로 변환한다.
- 인증 토큰은 Keychain 에 저장한다 (UserDefaults 금지). 로그인/회원가입은 `AuthRepository` 로 추상화.

### API 연결 시 체크리스트 (추후)

1. `Core/Networking` 에 `APIClient`(URLSession + async/await), `Endpoint`, `APIError` 추가
2. `Data/Remote` 에 DTO 와 `Remote*Repository` 구현
3. `Data/Mappers` 에서 DTO ↔ Domain 변환
4. `AppContainer` 에서 Mock → Remote 교체 (환경별 base URL 은 `.xcconfig` 로 분리)
5. 토큰 갱신/401 처리, 이미지 업로드(멀티파트 또는 presigned URL) 방식은 백엔드 확정 후 결정

## 도메인 모델 (초안)

기능 명세서 기준. 필드는 API 확정 시 조정될 수 있다.

```swift
struct User { id, nickname, email }

struct TripRoom {
    id, title
    startDate, endDate
    inviteCode            // 예: "JAM-4F7K"
    ownerID
    members: [Member]
    capsule: TimeCapsule? // MVP: 방당 1개
}

struct DiaryEntry {
    id, roomID, authorID
    text
    photoURLs / photoData
    visibility: Visibility    // .friends(공개 일기) | .capsule(비밀 일기)
    createdAt
}

struct TimeCapsule {
    id, roomID, title
    openAt: Date
    status: Status            // .locked | .opened
    participants: [Member]
}
```

### 핵심 비즈니스 규칙 (MVP)

- 공개 일기(`friends`)는 작성 즉시 그룹원 전체에게 보인다. 피드는 **최신순만** 지원.
- 비밀 일기(`capsule`)는 **타임캡슐 공개 시각 전까지 작성자 본인만** 볼 수 있다.
- 공개 시각(`openAt`)이 지나면 그룹원 전원의 비밀 기록이 열린다 (상태: locked → opened).
- 타임캡슐은 **방당 1개**. 공개 날짜/시간은 방 생성 시 함께 지정한다.
- 초대 코드로만 입장 가능한 **비공개 방**이다.
- MVP 제외: 댓글, 이모지 반응, 음성 녹음, AI 요약, 복수 타임캡슐, 복잡한 알림.
  (알림 없이 앱 진입 시 상태를 확인한다.)
- 타임캡슐 공개 여부 판단은 **서버 시각 기준**이 원칙이다. Mock 단계에서는 `Date()` 를 쓰되
  `Clock`/`DateProvider` 로 감싸 테스트와 추후 교체가 가능하게 한다.

## 화면 / 네비게이션

앱 흐름: `Welcome → (SignUp | Login) → Home → …`

| 화면 | Feature | 비고 |
|---|---|---|
| 초기 화면 (Welcome) | Onboarding | 시작하기 → 회원가입 / 이미 계정이 있어요 → 로그인 |
| 로그인 / 회원가입 | Auth | 성공 시 Home |
| 홈 | Home | 참여 중인 여행 목록, 방 만들기, 초대 코드 입력 |
| 여행 방 만들기 | Room | 제목, 기간, 인원, **타임캡슐 공개 날짜·시간** |
| 초대 코드 발급 | Room | 코드 복사/공유, 방으로 들어가기 |
| 초대 코드 입력 | Room | 코드 검증 → 방 미리보기 → 참여 |
| 여행 방 메인 | Room | 상단 `피드 \| 기록` 세그먼트 탭. 타임캡슐 상태 카드, + 버튼으로 일기 작성 |
| 일기 작성 | Diary | 사진, 글, 공개 범위(친구 공개 / 타임캡슐 보관) |
| 타임캡슐 만들기 | Capsule | 비밀 일기 작성. 공개 일정은 방에서 정한 값을 따름 |
| 타임캡슐 상세 | Capsule | 공개 전(잠금·카운트다운) / 공개 후(그룹원 기록) 두 상태 |

- 화면 전환은 `Route` enum + `NavigationStack(path:)` 로 관리하고, 각 Feature 가 자기 Route 를 가진다.
- 모달성 화면(일기 작성, 방 만들기, 초대 코드 입력)은 `.sheet` / `.fullScreenCover` 로 띄운다.
- 인증 상태에 따라 루트(Onboarding/Auth ↔ Home)를 `AppRouter` 에서 전환한다.
- 사진 선택은 `PhotosPicker` (PhotosUI) 를 사용한다.

## 디자인 시스템

디자인 원본: Figma `https://www.figma.com/design/FXLvt7SnG86zocIzFurV3N/짜미`
(페이지 "디자인을 모르느냐 하지 마시고" 안의 `Jammy Design System`, `Jammy Components` 프레임과 각 화면)

**색/폰트/간격을 임의의 값으로 하드코딩하지 않는다.** 아래 값을 기준으로 쓴다.

> 현재 **색상만 Xcode Asset Catalog 에 등록**되어 있다. 폰트·간격·반경·그림자용 Swift 토큰 코드는 아직 만들지 않았다
> (필요해지면 사용자에게 확인 후 추가). 아래 표는 그때까지의 값 기준표다.

### Color (Assets.xcassets/Colors)

| 토큰 | Hex | 용도 |
|---|---|---|
| primary | #E84D5B | 메인 브랜드, 주요 버튼, 선택 상태 |
| primaryPressed | #D63E4B | 눌림 상태 |
| primarySoft | #FDEBED | 연한 선택 배경, 칩 |
| secondary | #F6C453 | 버터 옐로우, 포인트·FAB |
| secondarySoft | #FFF3C9 | 카테고리/빈 상태 배경 |
| accentPink | #F58A95 | 보조 일러스트 |
| accentGreen | #7FA66A | 자연/긍정 포인트 |
| background | #FFF9F4 | 앱 기본 배경 (따뜻한 크림) |
| surface | #FFFFFF | 카드, 시트 |
| surfaceWarm | #FFF4E8 | 강조 카드, 컬렉션 |
| textPrimary | #3B292B | 제목/본문 |
| textSecondary | #796467 | 설명/메타 |
| textTertiary | #A58F91 | 플레이스홀더/비활성 |
| border | #EEDFD9 | 카드 테두리, 구분선 |
| success / warning / error | #69A86F / #F2A93B / #D94A52 | 상태 |
| greenSoft / yellowText / neutralChip / disabled | #EDF4E8 / #8A6500 / #F5EFEC / #F2E8E5 | 칩·비활성 |

- 위 색은 모두 `Assets.xcassets/Colors/` 에 컬러 세트로 등록되어 있다. 이름은 `Jammy` 접두사 + PascalCase 이다
  (예: `JammyPrimary`, `JammyTextSecondary`, `JammySurfaceWarm`). 표의 camelCase 토큰명 앞에 `Jammy` 를 붙이고 첫 글자를 대문자로 쓰면 된다.
- 접두사를 붙인 이유: `primary`/`secondary` 는 SwiftUI 의 `Color.primary`/`Color.secondary` 와 충돌하기 때문이다.
- 사용: `Color(.jammyPrimary)` (Xcode 가 생성하는 에셋 심볼). 문자열 `Color("JammyPrimary")` 는 쓰지 않는다.
- 색을 추가/변경할 때는 컬러 세트를 수정하고, Figma 의 `Jammy/Color` 변수와 동기화한다.
- 다크 모드: 디자인이 아직 없다. 우선 라이트 고정(`preferredColorScheme(.light)`)으로 두고, 디자인 확정 후 대응한다.
- 모든 요소를 빨강으로 칠하지 않는다. 한 화면에서 강조색은 3~4개 이내.

### Typography (Pretendard)

Dynamic Type 을 고려해 `relativeTo:` 를 지정한다. (Swift 토큰 코드는 아직 없음)

| 스타일 | 크기/굵기 | 자간 |
|---|---|---|
| display | 36 / 800 | -2.5% |
| h1 | 30 / 800 | -2% |
| h2 | 24 / 700 | -2% |
| h3 | 20 / 700 | -2% |
| h4 | 18 / 700 | -1.5% |
| bodyLarge | 17 / 500 | -1% |
| body | 16 / 400 | -1% |
| bodySmall | 14 / 400 | -1% |
| label | 14 / 600 | 0 |
| button | 15 / 600 | 0 |
| caption | 12 / 500 | 0 |
| micro | 11 / 500 | 0 |

- Pretendard 는 `UIAppFonts` 로 등록되어 있다 (위 "기술 스택" 참고).
- 시스템 폰트를 임의로 섞어 쓰지 않는다.

### Spacing / Radius / Shadow

- **Spacing**(4pt 기준): 4, 8, 12, 16, 20, 24, 28, 32, 40, 48, 64, 80
  - 화면 좌우 패딩 20, 카드 패딩 16, 섹션 간격 32, 같은 그룹 간격 16
- **Radius**: 8 태그 / 12 작은 컨트롤 / 14 버튼·입력 / 16 검색 / 18 카드 / 20 잼 카드 / 24 피처드 / 28 바텀시트 / full 칩·아바타
- **Shadow**(따뜻한 색, 진한 검정 금지):
  - L1 `0 2 6 rgba(59,41,43,.06)` 카드
  - L2 `0 6 16 rgba(59,41,43,.08)` 드롭다운·시트
  - L3 `0 12 32 rgba(59,41,43,.12)` 모달
  - Playful `0 8 20 rgba(232,77,91,.12)` 특별 카드

### 공통 컴포넌트 (Core/DesignSystem/Components)

Figma `Jammy Components` 와 1:1 대응하는 SwiftUI 컴포넌트를 만들어 재사용한다.
화면에서 버튼/칩/카드를 직접 스타일링하지 말고 컴포넌트를 쓴다.

| Figma | SwiftUI |
|---|---|
| Button (Primary/Soft/Secondary/Ghost/Disabled), 높이 48, 라운드 14 | `JammyButton(style:)` / `ButtonStyle` |
| IconButton, FAB(56, 라운드 18, 옐로우) | `JammyIconButton`, `JammyFAB` |
| Chip (Primary/Yellow/Green/Neutral/Solid) | `JammyChip(kind:)` |
| Input (Default/Focus/Error/Filled) | `JammyTextField` |
| Avatar (S 32/M 40/L 56) | `JammyAvatar(size:)` |
| Segmented Tabs (피드/기록) | `RoomTabs` |
| TopBar / SectionHeader / BottomBar | `JammyTopBar`, `SectionHeader`, `BottomActionBar` |
| JamCard / TripCard / FeedCard / CapsuleCard | 각 `*Card` 뷰 |
| Notice, Illustration/JamJar | `NoticeBanner`, `JamJarView` |

## 코드 컨벤션

- Swift API Design Guidelines 를 따른다. 타입은 UpperCamelCase, 나머지는 lowerCamelCase.
- 파일 하나에 주요 타입 하나. 파일명 = 타입명.
- View 는 작게 쪼갠다. `body` 가 길어지면 서브뷰(`private struct`) 또는 `@ViewBuilder` 로 분리.
- `AnyView` 는 쓰지 않는다. 조건부 UI 는 `@ViewBuilder`/`Group` 으로.
- 강제 언래핑(`!`), `try!`, `fatalError` 는 쓰지 않는다 (프리뷰용 샘플 데이터 제외).
- 매직 넘버 금지: 간격/반경/색은 토큰으로.
- 접근성: 아이콘 버튼에는 `accessibilityLabel` 을 달고, 터치 영역은 최소 44×44pt 를 지킨다.
- 문자열은 우선 한국어 하드코딩 대신 `String(localized:)`/String Catalog 를 쓸 수 있게 구조를 열어둔다.
- 주석은 "왜"가 필요한 곳에만 쓴다. 코드가 설명하는 것은 주석으로 반복하지 않는다.

## UI 톤 & 카피

친구가 재밌는 걸 알려주는 느낌으로, 딱딱한 여행 업계 용어는 피한다.

- 좋은 예: "이 잼 저장하기", "방으로 들어가기", "서로의 기억이 열렸어요", "오늘의 순간 담기"
- 피할 예: "목적지 추가", "일정 엔터티 관리", "여행 자산 생성"
- 용어: 공개 일기 = 친구에게 공개, 비밀 일기 = 타임캡슐에 보관, 여행 방, 초대 코드
- 잼 병 메타포는 포인트로만 쓴다. 모든 화면에 남발하지 않는다.
- 모션: 저장 시 카드가 살짝 튀어오르고(120~180ms), 타임캡슐 공개는 350~500ms 의 축하 연출. 과한 바운스는 피한다.

## 테스트

- ViewModel 단위 테스트를 우선한다 (Swift Testing 또는 XCTest). Mock Repository 를 주입해 성공/실패/빈 상태를 검증한다.
- 타임캡슐 잠금/공개 로직은 `DateProvider` 를 주입해 시간 경계(공개 직전/직후)를 테스트한다.
- 비즈니스 규칙(비밀 일기는 공개 전 본인만 조회)은 반드시 테스트로 고정한다.

## 작업 방식 (Claude 에게)

- 새 기능은 **Domain Model → Repository 프로토콜 → Mock 구현 → ViewModel → View** 순서로 만든다.
- View 를 만들 때는 먼저 Figma 의 해당 화면/컴포넌트를 확인하고, 토큰과 공통 컴포넌트를 재사용한다.
- 백엔드 스펙이 없는 부분은 임의로 가정해 구현하지 말고, Repository 프로토콜과 Mock 으로 막아 두고
  가정한 내용을 PR/응답에 명시한다.
- 이 문서에 없는 결정(서드파티 도입, 로컬 DB 선택(SwiftData 등), 다크 모드, 푸시 알림)은 구현 전에 사용자에게 확인한다.
- 빌드/테스트 명령은 프로젝트 생성 후 이 문서에 추가한다.

## 아직 정해지지 않은 것 (TBD)

- 백엔드 API 스펙, 인증 방식(이메일 / 소셜 로그인 여부), 이미지 업로드 방식
- 로컬 캐시/영속화 (SwiftData 사용 여부)
- 푸시 알림 (타임캡슐 공개 알림은 2순위 기능)
- 다크 모드 디자인
- 앱 번들 ID, 배포 환경(Dev/Staging/Prod) 구성
