# iTerm2 Tab Group 기능 구현 문서

## 개요

### 목적
Chrome 브라우저의 탭 그룹 기능을 iTerm2에 구현하여, 여러 터미널 탭을 논리적으로 그룹화하고 관리할 수 있도록 한다.

### Chrome 탭 그룹 참조 기능
- 탭을 색상별 그룹으로 묶기
- 그룹 헤더에 이름과 색상 점 표시
- 클릭으로 그룹 접기/펼치기
- 8가지 사전 정의 색상 (Grey, Blue, Red, Yellow, Green, Pink, Purple, Cyan)
- 그룹 탭 아래 색상 언더라인 표시

---

## 구현 내용

### 1. 새로 생성된 파일

#### PSMTabBarControl (ThirdParty)

| 파일 | 설명 |
|------|------|
| `PSMTabGroup.h` | 탭 그룹 모델 헤더 |
| `PSMTabGroup.m` | 탭 그룹 모델 구현 - 8가지 Chrome 색상, 식별자, 이름, 접힘 상태 관리 |

#### iTerm2 Sources

| 파일 | 설명 |
|------|------|
| `iTermTabGroup.h/m` | iTerm2용 탭 그룹 모델 - 색상, 이름, 탭 GUID 목록, arrangement 저장/복원 |
| `iTermTabGroupManager.h/m` | 탭 그룹 관리자 - 그룹 생성/삭제, 탭 추가/제거, 접힘 토글 |
| `iTermTabGroupColorPickerViewController.h/m` | 8색 색상 선택기 UI |
| `iTermTabGroupNameEditor.h/m` | 그룹 이름 편집 팝오버 |
| `iTermTabGroupHeaderCell.h/m` | 접힌 그룹 표시용 셀 |
| `PseudoTerminal+TabGroups.h/m` | PseudoTerminal 확장 - PSMTabGroupDataSource 구현 |
| `PseudoTerminal+TabGroupDelegate.h/m` | 탭 그룹 델리게이트 (미사용) |

### 2. 수정된 파일

#### PSMTabBarControl

| 파일 | 변경 내용 |
|------|----------|
| `PSMTabBarControl.h` | `PSMTabGroupDataSource` 프로토콜 추가, `tabGroupDataSource` 프로퍼티 추가 |
| `PSMTabBarControl.m` | `#import "PSMTabGroup.h"` 추가 |
| `PSMTabStyle.h` | 그룹 드로잉 메서드 (optional) 추가 |
| `PSMYosemiteTabStyle.m` | 그룹 헤더/언더라인 렌더링 구현 |

#### iTerm2 Sources

| 파일 | 변경 내용 |
|------|----------|
| `PseudoTerminal.m` | `[self connectTabBarToTabGroups]` 호출 추가 (라인 749) |

### 3. Xcode 프로젝트

- `PSMTabGroup.h`, `PSMTabGroup.m` 파일 참조 추가
- iTerm2SharedARC 타겟의 Sources 빌드 페이즈에 추가

---

## 구현 상세

### PSMTabGroupDataSource 프로토콜

```objc
@protocol PSMTabGroupDataSource <NSObject>
@optional
- (NSArray<PSMTabGroup *> *)tabGroupsForTabBarControl:(PSMTabBarControl *)tabBarControl;
- (PSMTabGroup *)tabBarControl:(PSMTabBarControl *)tabBarControl
       groupForTabWithIdentifier:(id)identifier;
- (void)tabBarControl:(PSMTabBarControl *)tabBarControl
    didClickGroupHeader:(PSMTabGroup *)group;
- (void)tabBarControl:(PSMTabBarControl *)tabBarControl
    createGroupForTabWithIdentifier:(id)identifier;
- (void)tabBarControl:(PSMTabBarControl *)tabBarControl
          renameGroup:(PSMTabGroup *)group;
- (void)tabBarControl:(PSMTabBarControl *)tabBarControl
    changeColorForGroup:(PSMTabGroup *)group;
- (void)tabBarControl:(PSMTabBarControl *)tabBarControl
         ungroupGroup:(PSMTabGroup *)group;
- (void)tabBarControl:(PSMTabBarControl *)tabBarControl
           closeGroup:(PSMTabGroup *)group;
@end
```

### PSMTabStyle 그룹 드로잉 메서드 (Optional)

```objc
- (void)drawGroupHeaderForGroup:(PSMTabGroup *)group
                         inRect:(NSRect)rect
                      collapsed:(BOOL)collapsed;
- (void)drawGroupUnderlineForGroup:(PSMTabGroup *)group
                          fromRect:(NSRect)startRect
                            toRect:(NSRect)endRect;
- (CGFloat)groupHeaderHeight;
- (CGFloat)widthForGroupHeader:(PSMTabGroup *)group;
- (CGFloat)groupHeaderToTabSpacing;
```

### 색상 상수 (PSMTabGroup)

```objc
+ (NSArray<NSColor *> *)predefinedColors {
    return @[
        [NSColor colorWithRed:0.62 green:0.62 blue:0.62 alpha:1.0],  // Grey
        [NSColor colorWithRed:0.54 green:0.70 blue:0.98 alpha:1.0],  // Blue
        [NSColor colorWithRed:0.96 green:0.54 blue:0.54 alpha:1.0],  // Red
        [NSColor colorWithRed:0.98 green:0.87 blue:0.54 alpha:1.0],  // Yellow
        [NSColor colorWithRed:0.55 green:0.85 blue:0.64 alpha:1.0],  // Green
        [NSColor colorWithRed:0.96 green:0.70 blue:0.82 alpha:1.0],  // Pink
        [NSColor colorWithRed:0.76 green:0.68 blue:0.95 alpha:1.0],  // Purple
        [NSColor colorWithRed:0.54 green:0.88 blue:0.89 alpha:1.0],  // Cyan
    ];
}
```

### 렌더링 상수 (PSMYosemiteTabStyle)

```objc
static const CGFloat kPSMTabGroupHeaderHeight = 20.0;
static const CGFloat kPSMTabGroupHeaderPadding = 6.0;
static const CGFloat kPSMTabGroupColorDotSize = 8.0;
static const CGFloat kPSMTabGroupUnderlineHeight = 3.0;
static const CGFloat kPSMTabGroupHeaderToTabSpacing = 2.0;
```

---

## 현재 상태 및 알려진 문제점

### 빌드 상태
- **개별 파일 컴파일**: 성공 (PSMTabGroup.m, iTermTabGroup.m 등)
- **전체 빌드**: 코드 서명 인증서 문제로 실패 (코드 문제 아님)

### 미완성/미동작 항목

#### 1. 탭 그룹 생성 UI 진입점 없음
- **문제**: 사용자가 탭 그룹을 생성할 수 있는 메뉴나 버튼이 없음
- **필요한 작업**:
  - 탭 컨텍스트 메뉴에 "Create Tab Group" 항목 추가
  - 또는 탭바에 그룹 생성 버튼 추가
  - 키보드 단축키 바인딩

#### 2. 그룹 드로잉 호출 검증 필요
- **문제**: `drawTabGroupsForBar:inRect:clipRect:` 메서드가 실제로 호출되는지 확인 필요
- **필요한 작업**:
  - `drawTabBar:inRect:clipRect:horizontal:withOverflow:` 에서 호출 확인
  - 그룹이 있을 때 레이아웃 계산이 올바른지 검증

#### 3. 탭 레이아웃 조정 미구현
- **문제**: 그룹 헤더가 표시될 공간이 탭 레이아웃에 반영되지 않음
- **필요한 작업**:
  - `PSMTabBarControl`의 셀 레이아웃 계산에 그룹 헤더 너비 반영
  - 그룹별로 탭 위치 조정

#### 4. 그룹 접힘 시 탭 숨김 미구현
- **문제**: 그룹이 접혀도 해당 그룹의 탭이 계속 표시됨
- **필요한 작업**:
  - `PSMTabBarControl`에서 접힌 그룹의 탭 숨김 처리
  - 접힌 그룹의 대표 셀만 표시

#### 5. 드래그 앤 드롭 미구현
- **문제**: 탭을 드래그하여 그룹에 추가/제거하는 기능 없음
- **필요한 작업**:
  - 탭 드래그 시 그룹 헤더 위에 드롭 처리
  - 그룹 간 탭 이동

#### 6. 탭 순서와 그룹 연동 미검증
- **문제**: 같은 그룹의 탭이 연속으로 배치되는지 확인 필요
- **필요한 작업**:
  - 그룹에 탭 추가 시 기존 그룹 탭 옆으로 이동
  - 탭 순서 재정렬 로직

#### 7. Arrangement 저장/복원 미검증
- **문제**: 창 복원 시 탭 그룹 정보가 올바르게 복원되는지 확인 필요
- **필요한 작업**:
  - `addTabGroupsToArrangement:` 호출 위치 확인
  - `restoreTabGroupsFromArrangement:` 호출 위치 확인

#### 8. 컨텍스트 메뉴 연결 미완료
- **문제**: `tabGroupContextMenuForTab:` 메서드가 탭바의 실제 컨텍스트 메뉴에 연결되지 않음
- **필요한 작업**:
  - `PSMTabBarControl`의 컨텍스트 메뉴 델리게이트와 연결

---

## 다음 단계 권장 사항

### 우선순위 높음
1. **탭 컨텍스트 메뉴에 그룹 옵션 추가** - 사용자가 기능에 접근할 수 있도록
2. **그룹 드로잉 디버깅** - 실제로 그려지는지 확인
3. **탭 레이아웃에 그룹 헤더 공간 반영**

### 우선순위 중간
4. **그룹 접힘 시 탭 숨김 구현**
5. **컨텍스트 메뉴 연결**
6. **Arrangement 저장/복원 검증**

### 우선순위 낮음
7. **드래그 앤 드롭 구현**
8. **키보드 단축키 추가**
9. **설정 UI 추가 (그룹 기능 활성화/비활성화)**

---

## 파일 위치 참조

```
iTerm2/
├── sources/
│   ├── iTermTabGroup.h                          # 라인 1-50
│   ├── iTermTabGroup.m                          # 라인 1-150
│   ├── iTermTabGroupManager.h                   # 라인 1-60
│   ├── iTermTabGroupManager.m                   # 라인 1-200
│   ├── iTermTabGroupColorPickerViewController.h # 라인 1-30
│   ├── iTermTabGroupColorPickerViewController.m # 라인 1-150
│   ├── iTermTabGroupNameEditor.h                # 라인 1-25
│   ├── iTermTabGroupNameEditor.m                # 라인 1-100
│   ├── iTermTabGroupHeaderCell.h                # 라인 1-20
│   ├── iTermTabGroupHeaderCell.m                # 라인 1-80
│   ├── PseudoTerminal+TabGroups.h               # 라인 1-89
│   ├── PseudoTerminal+TabGroups.m               # 라인 1-517
│   └── PseudoTerminal.m                         # 수정: 라인 749
│
└── ThirdParty/PSMTabBarControl/source/
    ├── PSMTabGroup.h                            # 라인 1-40
    ├── PSMTabGroup.m                            # 라인 1-120
    ├── PSMTabBarControl.h                       # 수정: PSMTabGroupDataSource 추가
    ├── PSMTabBarControl.m                       # 수정: import 추가
    ├── PSMTabStyle.h                            # 수정: 라인 91-110 (optional 메서드)
    └── PSMYosemiteTabStyle.m                    # 수정: 그룹 렌더링 구현
```

---

## 작성 정보

- **작성일**: 2025-02-06
- **작성자**: Claude (AI Assistant)
- **버전**: 초기 구현 (미완성)
