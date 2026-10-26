---
name: pill-toggle-filter-expert
description: Next.js App Router 기반 알약(Pill) 모양 다중/단일 토글 필터 바, 전체 선택/전체 해제, Ctrl 키 복수 선택, URL Query Parameter 동기화 및 Prisma ORM 연동 서버 사이드 필터링 표준 패턴 가이드 스킬.
---

# 알약(Pill) 토글 필터 및 URL 동기화 전문가 스킬 (`pill-toggle-filter-expert`)

본 스킬은 Next.js App Router 및 Prisma ORM 환경에서 알약(Pill) 모양의 다중/단일 토글 필터 바 UI를 구축하고, URL 쿼리 파라미터(`roles`, `statuses` 등)와의 실시간 양방향 동기화 및 서버 사이드 필터링을 일관되게 구현하기 위한 표준 규칙을 제공한다.

---

## 1. 주요 특징 및 적용 시점

### 적용 대상
- 회원 관리, 게시판 관리, 버그 제보 관리, 자료실 등 **다중 분류/상태/권한 필터링**이 필요한 모든 목록 페이지.

### 핵심 기능
1. **알약(Pill) 버튼 UI**: 둥근 모서리(`rounded-full`), 상태 표시점(`w-1.5 h-1.5 rounded-full`), 활성/비활성 테마 색상 적용.
2. **단일 선택(기본) 및 Ctrl 키 복수 선택**: 클릭 시 해당 항목만 유일하게 선택되며, `Ctrl`(또는 `Cmd`) 키를 누른 채 클릭 시 복수 선택(토글)이 가능한다.
3. **하단 팁(`show-bottom-tip`) 안내 연동**: 필터 하단에 `💡 팁: 다른 항목 선택 시 단일 선택되며, Ctrl 키를 누르고 클릭하면 복수 선택됩니다.` 힌트 UI 노출.
4. **전체 선택 / 전체 해제**: 한 번의 클릭으로 해당 그룹의 모든 필터 선택/해제.
5. **URL SearchParams 양방향 동기화**: 필터 변경 시 `groups=boards,archive` 형식으로 URL 업데이트, 브라우저 새로고침 및 공유 시 상태 보존.
6. **Prisma 서버 사이드 필터링**: `where` 조건절 연동 및 `select` 속성 명시로 정확한 쿼리 조회.
7. **폰트 가시성 규약 준수**: minimum 폰트 크기 `text-xs`(16px) 이상 적용.

---

## 2. 표준 구현 패턴

### A. Client Component (`FilterBar` 또는 `ClientPage`)

```tsx
"use client"

import { useState, useCallback, useEffect } from "react"
import { useRouter, useSearchParams, usePathname } from "next/navigation"
import { Button } from "@/components/ui/button"

const ALL_ROLES = ["ADMIN", "SECRETARY", "MODERATOR", "DEPT_LEADER", "USER"] as const
type RoleType = (typeof ALL_ROLES)[number]

const ROLE_LABEL_MAP: Record<RoleType, string> = {
  ADMIN: "관리자",
  SECRETARY: "간사",
  MODERATOR: "노회장",
  DEPT_LEADER: "부서장",
  USER: "일반 회원",
}

const ROLE_COLOR_MAP: Record<RoleType, { active: string; inactive: string }> = {
  ADMIN: {
    active: "bg-red-600 text-white border-red-600 shadow-sm dark:bg-red-700 dark:border-red-700",
    inactive: "bg-background text-red-700 dark:text-red-400 border-red-200 dark:border-red-900/50 hover:bg-red-50 dark:hover:bg-red-950/40",
  },
  SECRETARY: {
    active: "bg-purple-600 text-white border-purple-600 shadow-sm dark:bg-purple-700 dark:border-purple-700",
    inactive: "bg-background text-purple-700 dark:text-purple-400 border-purple-200 dark:border-purple-900/50 hover:bg-purple-50 dark:hover:bg-purple-950/40",
  },
  MODERATOR: {
    active: "bg-blue-600 text-white border-blue-600 shadow-sm dark:bg-blue-700 dark:border-blue-700",
    inactive: "bg-background text-blue-700 dark:text-blue-400 border-blue-200 dark:border-blue-900/50 hover:bg-blue-50 dark:hover:bg-blue-950/40",
  },
  DEPT_LEADER: {
    active: "bg-emerald-600 text-white border-emerald-600 shadow-sm dark:bg-emerald-700 dark:border-emerald-700",
    inactive: "bg-background text-emerald-700 dark:text-emerald-400 border-emerald-200 dark:border-emerald-900/50 hover:bg-emerald-50 dark:hover:bg-emerald-950/40",
  },
  USER: {
    active: "bg-slate-600 text-white border-slate-600 shadow-sm dark:bg-slate-700 dark:border-slate-700",
    inactive: "bg-background text-slate-700 dark:text-slate-400 border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-900/40",
  },
}

function parseRolesParam(param: string | null): Set<RoleType> {
  if (!param) return new Set(ALL_ROLES)
  const parsed = param.split(",").filter((r) => (ALL_ROLES as readonly string[]).includes(r)) as RoleType[]
  return new Set(parsed)
}

export function RoleFilterBar() {
  const router = useRouter()
  const pathname = usePathname()
  const searchParams = useSearchParams()

  const [activeRoles, setActiveRoles] = useState<Set<RoleType>>(() =>
    parseRolesParam(searchParams.get("roles"))
  )

  useEffect(() => {
    setActiveRoles(parseRolesParam(searchParams.get("roles")))
  }, [searchParams])

  const pushRolesToUrl = useCallback(
    (nextRoles: Set<RoleType>) => {
      const params = new URLSearchParams(searchParams.toString())
      if (nextRoles.size === ALL_ROLES.length) {
        params.delete("roles")
      } else {
        params.set("roles", Array.from(nextRoles).join(","))
      }
      params.set("page", "1") // 필터 변경 시 1페이지로 이동
      router.push(`${pathname}?${params.toString()}`)
    },
    [searchParams, pathname, router]
  )

  const isAllSelected = activeRoles.size === ALL_ROLES.length

  const selectAll = () => {
    const next = new Set<RoleType>(ALL_ROLES)
    setActiveRoles(next)
    pushRolesToUrl(next)
  }

  const deselectAll = () => {
    const next = new Set<RoleType>()
    setActiveRoles(next)
    pushRolesToUrl(next)
  }

  const toggleRole = (role: RoleType, isCtrlPressed: boolean) => {
    let nextRoles: Set<RoleType>
    if (isCtrlPressed) {
      // Ctrl/Cmd 클릭 시 복수 선택 토글
      nextRoles = new Set(activeRoles)
      if (nextRoles.has(role)) {
        nextRoles.delete(role)
      } else {
        nextRoles.add(role)
      }
    } else {
      // 일반 클릭 시 단일 선택
      nextRoles = new Set([role])
    }
    setActiveRoles(nextRoles)
    pushRolesToUrl(nextRoles)
  }

  return (
    <div className="flex flex-col gap-2 border-y py-3 px-6 bg-muted/20">
      <div className="flex flex-wrap items-center gap-2">
        <span className="text-xs font-semibold text-muted-foreground mr-1">역할:</span>

        {ALL_ROLES.map((role) => {
          const isActive = activeRoles.has(role)
          const colors = ROLE_COLOR_MAP[role]
          return (
            <button
              key={role}
              type="button"
              onClick={(e) => toggleRole(role, e.ctrlKey || e.metaKey)}
              className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full border text-xs font-semibold transition-all duration-150 select-none ${
                isActive ? colors.active : colors.inactive
              }`}
            >
              <span
                className={`w-1.5 h-1.5 rounded-full ${
                  isActive ? "bg-white/80" : "opacity-60 bg-current"
                }`}
              />
              {ROLE_LABEL_MAP[role]}
            </button>
          )
        })}

        <div className="flex items-center gap-1 ml-auto sm:ml-2">
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={selectAll}
            disabled={isAllSelected}
            className="h-7 px-2.5 text-xs font-medium rounded-full"
          >
            전체 선택
          </Button>
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={deselectAll}
            disabled={activeRoles.size === 0}
            className="h-7 px-2.5 text-xs font-medium rounded-full"
          >
            전체 해제
          </Button>
        </div>
      </div>

      <p className="text-xs text-muted-foreground pt-1 flex items-center gap-1">
        💡 <strong>필터 팁:</strong> 다른 항목 선택 시 <strong>단일 선택</strong>되며, <strong>Ctrl(Cmd) 키</strong>를 누른 채 클릭하면 <strong>복수 선택</strong>이 가능한다.
      </p>
    </div>
  )
}
```

---

### B. Server Component (`page.tsx`)

```tsx
interface Props {
  searchParams: Promise<{ roles?: string; page?: string }>
}

export default async function Page({ searchParams }: Props) {
  const { roles: rolesParam, page } = await searchParams
  const activeRoles = rolesParam
    ? rolesParam.split(",").filter((r) => ALL_ROLES.includes(r as any))
    : Array.from(ALL_ROLES)

  const whereClause = {
    role: { in: activeRoles }
  }

  const [items, totalCount] = await prisma.$transaction([
    prisma.user.findMany({
      where: whereClause,
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        isActive: true,
        createdAt: true,
      },
    }),
    prisma.user.count({ where: whereClause }),
  ])

  return (
    // Client Component에 props 전달
  )
}
```

---

## 3. 체크리스트

- [ ] 필터 버튼이 알약(`rounded-full`) 및 가시성 폰트(`text-xs` 이상) 규칙을 준수하는가?
- [ ] 일반 클릭 시 단일 선택, Ctrl(Cmd) 클릭 시 복수 선택 토글이 동작하는가?
- [ ] 하단 팁(`show-bottom-tip`) 조작 안내 문구가 노출되어 있는가?
- [ ] 전체 선택 / 전체 해제 동작이 유기적으로 동작하는가?
- [ ] URL `roles`, `statuses` 쿼리 스트링과 동기화되어 새로고침 후에도 유지되는가?
- [ ] Prisma 쿼리 시 `select` 구문이 명시되어 있는가?
