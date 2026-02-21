#!/bin/bash
cd "$(dirname "$0")"

# Renkler
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

TARIH() {
  TZ="Europe/Istanbul" date "+%Y-%m-%d %H:%M:%S"
}
KULLANICI=$(whoami)
HOST=$(hostname)

bekle() {
  echo ""
  echo -e "${DIM}[Enter] Ana menuye don${NC}"
  read -r
}

# Mevcut dali push et; upstream yoksa origin/<dal> ile ilk kez baglar.
push_current_branch() {
  local current_branch has_upstream
  current_branch=$(git branch --show-current 2>/dev/null)

  if [ -n "$current_branch" ]; then
    if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
      has_upstream=1
    else
      has_upstream=0
    fi
  else
    has_upstream=1
  fi

  if [ "$has_upstream" -eq 1 ]; then
    git push
  else
    git push -u origin "$current_branch"
  fi
}

# Mevcut branch adini guvenli sekilde al (detached HEAD dahil)
get_branch() {
  local b
  b=$(git branch --show-current 2>/dev/null)
  if [ -n "$b" ]; then
    echo "$b"
  else
    # Detached HEAD durumu
    local desc
    desc=$(git describe --tags --exact-match 2>/dev/null)
    if [ -n "$desc" ]; then
      echo "($desc)"
    else
      local sha
      sha=$(git rev-parse --short HEAD 2>/dev/null)
      if [ -n "$sha" ]; then
        echo "(detached:$sha)"
      else
        echo "?"
      fi
    fi
  fi
}

dal_listele() {
  MEVCUT_BRANCH=$(git branch --show-current 2>/dev/null)
  DALLAR=()
  while IFS= read -r line; do
    # Detached HEAD satirini atla
    if [[ "$line" == *"detached"* ]] || [[ "$line" == *"HEAD detached"* ]]; then
      continue
    fi
    dal=$(echo "$line" | sed 's/^[* ]*//' | sed 's/ .*//')
    if [ -n "$dal" ]; then
      DALLAR+=("$dal")
    fi
  done < <(git branch 2>/dev/null)
  echo ""
  for i in "${!DALLAR[@]}"; do
    if [ "${DALLAR[$i]}" = "$MEVCUT_BRANCH" ]; then
      echo -e "  ${GREEN}$((i+1)))${NC} ${DALLAR[$i]} ${GREEN}<- buradasin${NC}"
    else
      echo -e "  ${GREEN}$((i+1)))${NC} ${DALLAR[$i]}"
    fi
  done

  # Remote branch'leri al - git branch -r ciktisi "  origin/xxx" formatindadir
  UZAK_DALLAR=()
  while IFS= read -r line; do
    # "origin/HEAD -> origin/main" gibi satirlari atla
    if [[ "$line" == *"->"* ]]; then
      continue
    fi
    # Boslugu temizle ve origin/ prefixini kaldir
    dal=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's|^origin/||')
    if [ -z "$dal" ]; then
      continue
    fi
    # Zaten yerel olanlari atla
    yerel=0
    for d in "${DALLAR[@]}"; do
      if [ "$d" = "$dal" ]; then yerel=1; break; fi
    done
    if [ "$yerel" = "0" ]; then
      UZAK_DALLAR+=("$dal")
    fi
  done < <(git branch -r 2>/dev/null)

  if [ ${#UZAK_DALLAR[@]} -gt 0 ]; then
    echo ""
    echo -e "  ${DIM}--- Sadece remote'ta ---${NC}"
    for i in "${!UZAK_DALLAR[@]}"; do
      echo -e "  ${GREEN}$((i+1+${#DALLAR[@]})))${NC} ${DIM}${UZAK_DALLAR[$i]} (remote)${NC}"
    done
  fi
  echo ""
  TUM_DALLAR=("${DALLAR[@]}" "${UZAK_DALLAR[@]}")
}

dal_sec() {
  local mesaj="$1"
  echo -n "$mesaj"
  read -r SECIM
  if [ -n "$SECIM" ] && [ "$SECIM" -ge 1 ] 2>/dev/null && [ "$SECIM" -le "${#TUM_DALLAR[@]}" ] 2>/dev/null; then
    SECILEN_DAL="${TUM_DALLAR[$((SECIM-1))]}"
  else
    SECILEN_DAL=""
    if [ -n "$SECIM" ]; then
      echo -e "${RED}Gecersiz secim!${NC}"
    fi
  fi
}

# Secilen dal remote-only mi kontrol et
is_remote_only() {
  local dal="$1"
  for d in "${DALLAR[@]}"; do
    if [ "$d" = "$dal" ]; then
      return 1  # Yerel dal
    fi
  done
  return 0  # Remote-only
}

get_main_ref() {
  if git show-ref --verify --quiet refs/remotes/origin/main 2>/dev/null; then
    echo "origin/main"
    return
  fi
  if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
    echo "main"
    return
  fi
  echo ""
}

branch_relation() {
  local head_ref="$1"
  local base_ref="$2"
  local rel
  rel=$(git rev-list --left-right --count "$base_ref...$head_ref" 2>/dev/null)
  if [ -z "$rel" ]; then
    echo ""
    return
  fi
  local behind ahead
  behind=$(echo "$rel" | awk '{print $1}')
  ahead=$(echo "$rel" | awk '{print $2}')
  echo "$ahead $behind"
}

show_compare_report() {
  local target="$1"
  local label="$2"

  if [ -z "$target" ]; then
    echo -e "${RED}Karsilastirma hedefi bulunamadi.${NC}"
    return
  fi

  local relation
  relation=$(branch_relation "HEAD" "$target")
  if [ -n "$relation" ]; then
    local ahead behind
    ahead=$(echo "$relation" | awk '{print $1}')
    behind=$(echo "$relation" | awk '{print $2}')
    echo -e "${BOLD}Durum:${NC} Bu dal ${label} karsisinda ${GREEN}$ahead ileri${NC}, ${YELLOW}$behind geri${NC}"
  fi

  echo ""
  echo -e "${BOLD}Dosya fark ozeti (${label}...HEAD):${NC}"
  local stat
  stat=$(git diff --stat "$target...HEAD" 2>/dev/null)
  if [ -z "$stat" ]; then
    echo -e "${YELLOW}Fark bulunamadi.${NC}"
  else
    echo "$stat"
  fi

  echo ""
  echo -e "${BOLD}Commit farklari (ilk 20):${NC}"
  git log --oneline --left-right --cherry "$target...HEAD" -20 2>/dev/null || true

  echo ""
  echo -e "Detayli diff acilsin mi? ${DIM}[Enter=Evet / h=Hayir]${NC}"
  read -r DETAY
  if [ "$DETAY" != "h" ] && [ "$DETAY" != "H" ]; then
    git diff "$target...HEAD"
  fi
}

merge_password_guard() {
  echo -e "${RED}!!! UYARI !!!${NC} Bu menu otomatik merge calistirir."
  echo -e "${YELLOW}Yanlis secim conflict veya istenmeyen kod birlesimine neden olabilir.${NC}"
  echo -n "Sifreyi gir: "
  read -r -s GIRILEN
  echo ""
  if [ "$GIRILEN" != "benkaan" ]; then
    echo -e "${RED}Sifre hatali. Islem iptal edildi.${NC}"
    return 1
  fi
  return 0
}

merge_target_into_current() {
  local target="$1"
  local label="$2"
  local current
  current=$(git branch --show-current 2>/dev/null)
  if [ -z "$current" ]; then
    echo -e "${RED}Detached HEAD durumunda merge engellendi.${NC}"
    return 1
  fi
  if [ "$target" = "$current" ] || [ "$label" = "$current" ]; then
    echo -e "${YELLOW}Ayni dali kendisiyle birlestiremezsin: $current${NC}"
    return 1
  fi
  if [ "$current" = "main" ] && { [ "$target" = "main" ] || [ "$target" = "origin/main" ] || [ "$label" = "main" ] || [ "$label" = "origin/main" ]; }; then
    echo -e "${YELLOW}main -> main merge engellendi.${NC}"
    return 1
  fi

  local rel
  rel=$(branch_relation "HEAD" "$target")
  if [ -n "$rel" ]; then
    local ahead behind
    ahead=$(echo "$rel" | awk '{print $1}')
    behind=$(echo "$rel" | awk '{print $2}')
    echo -e "Karsilastirma: ${BOLD}$label${NC} -> ${BOLD}$current${NC} | ${GREEN}$ahead ileri${NC}, ${YELLOW}$behind geri${NC}"
  fi

  echo -e "Merge onayi icin ${BOLD}evet${NC} yazin (${label} -> ${current}):"
  read -r ONAY
  if [ "$ONAY" != "evet" ]; then
    echo "Iptal edildi."
    return 1
  fi

  if git merge "$target"; then
    echo -e "${GREEN}Merge basarili: $label -> $current${NC}"
    return 0
  fi

  echo ""
  echo -e "${RED}Merge conflict olustu!${NC}"
  echo -e "  1) ${YELLOW}git status${NC} ile conflict dosyalarini kontrol et"
  echo -e "  2) Cozup ${YELLOW}git add . && git commit${NC}"
  echo -e "  3) Iptal icin ${YELLOW}git merge --abort${NC}"
  return 1
}

show_merge_precheck_list() {
  local current main_ref
  current=$(git branch --show-current 2>/dev/null)
  if [ -z "$current" ]; then
    echo -e "${RED}Detached HEAD durumunda liste olusturulamadi.${NC}"
    return
  fi

  main_ref=$(get_main_ref)
  echo -e "${BOLD}Merge Oncesi Durum Listesi${NC}"
  echo -e "${DIM}Referans dal: $current${NC}"
  if [ -n "$main_ref" ]; then
    echo -e "${DIM}Main referansi: $main_ref${NC}"
  fi
  echo ""
  printf "%-22s %-14s %-20s %-20s\n" "BRANCH" "SAHIP" "MEVCUDA GORE" "MAINE GORE"
  printf "%-22s %-14s %-20s %-20s\n" "------" "-----" "------------" "----------"

  while IFS= read -r b; do
    [ -z "$b" ] && continue
    owner=$(git log -1 --pretty=format:'%an' "$b" 2>/dev/null)
    [ -z "$owner" ] && owner="-"

    rel_cur=$(branch_relation "$b" "HEAD")
    if [ -n "$rel_cur" ]; then
      a_cur=$(echo "$rel_cur" | awk '{print $1}')
      g_cur=$(echo "$rel_cur" | awk '{print $2}')
      cur_txt="+$a_cur / -$g_cur"
    else
      cur_txt="-"
    fi

    if [ -n "$main_ref" ]; then
      rel_main=$(branch_relation "$b" "$main_ref")
      if [ -n "$rel_main" ]; then
        a_main=$(echo "$rel_main" | awk '{print $1}')
        g_main=$(echo "$rel_main" | awk '{print $2}')
        main_txt="+$a_main / -$g_main"
      else
        main_txt="-"
      fi
    else
      main_txt="-"
    fi

    printf "%-22s %-14s %-20s %-20s\n" "$b" "$owner" "$cur_txt" "$main_txt"
  done < <(git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)
}

merge_all_into_main_and_push() {
  local start_branch main_ref main_local main_base
  start_branch=$(git branch --show-current 2>/dev/null)
  if [ -z "$start_branch" ]; then
    echo -e "${RED}Detached HEAD durumunda bu islem yapilamaz.${NC}"
    return 1
  fi

  main_ref=$(get_main_ref)
  if [ -z "$main_ref" ]; then
    echo -e "${RED}main dali bulunamadi (ne local ne origin/main).${NC}"
    return 1
  fi

  main_local="main"
  if ! git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
    if [ "$main_ref" = "origin/main" ]; then
      if ! git checkout -b main origin/main; then
        echo -e "${RED}Local main olusturulamadi.${NC}"
        return 1
      fi
    fi
  else
    git checkout main || return 1
  fi
  git checkout "$main_local" >/dev/null 2>&1 || true

  if [ "$main_ref" = "origin/main" ]; then
    main_base="origin/main"
  else
    main_base="main"
  fi

  echo -e "${RED}!!! UYARI !!!${NC} Tum yerel branch'ler main'e merge edilecek."
  echo -e "Onay icin ${BOLD}evet${NC} yazin:"
  read -r TUM_ONAY
  if [ "$TUM_ONAY" != "evet" ]; then
    echo "Iptal edildi."
    return 1
  fi

  local merged=0 skipped=0 failed=0
  while IFS= read -r b; do
    [ -z "$b" ] && continue
    if [ "$b" = "main" ]; then
      skipped=$((skipped+1))
      echo -e "${DIM}Atlandi: main -> main merge yapilmaz.${NC}"
      continue
    fi
    echo ""
    echo -e "${BOLD}Merge deneniyor:${NC} $b -> main"
    rel=$(branch_relation "$b" "main")
    if [ -n "$rel" ]; then
      a=$(echo "$rel" | awk '{print $1}')
      g=$(echo "$rel" | awk '{print $2}')
      echo -e "Durum: ${GREEN}+$a${NC} / ${YELLOW}-$g${NC} (main'e gore)"
    fi
    if git merge "$b"; then
      merged=$((merged+1))
    else
      failed=$((failed+1))
      echo -e "${RED}Conflict olustu, seri merge durduruldu: $b${NC}"
      break
    fi
  done < <(git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)

  echo ""
  echo -e "Ozet: ${GREEN}$merged merge${NC}, ${YELLOW}$skipped atlandi${NC}, ${RED}$failed hata${NC}"
  echo -e "main pushlansin mi? ${DIM}[Enter=Evet / h=Hayir]${NC}"
  read -r MPUSH
  if [ "$MPUSH" != "h" ] && [ "$MPUSH" != "H" ]; then
    git push origin main
  fi
}

sync_all_local_branches() {
  local start_branch
  start_branch=$(git branch --show-current 2>/dev/null)
  if [ -z "$start_branch" ]; then
    echo -e "${RED}Detached HEAD durumunda bu islem yapilamaz.${NC}"
    return 1
  fi

  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo -e "${RED}Calisma alani temiz degil. Once commit/stash yap.${NC}"
    return 1
  fi

  echo -e "${RED}!!! UYARI !!!${NC} Tum local branch'ler tek tek senkronize edilecek (pull --rebase)."
  echo -e "Onay icin ${BOLD}evet${NC} yazin:"
  read -r SYNC_ONAY
  if [ "$SYNC_ONAY" != "evet" ]; then
    echo "Iptal edildi."
    return 1
  fi

  git fetch --all --prune
  local ok=0 skip=0 fail=0
  while IFS= read -r b; do
    [ -z "$b" ] && continue
    echo ""
    echo -e "${BOLD}Senkron:${NC} $b"
    if ! git checkout "$b" >/dev/null 2>&1; then
      echo -e "${RED}Branch'e gecilemedi: $b${NC}"
      fail=$((fail+1))
      break
    fi

    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "$b@{upstream}" 2>/dev/null)
    if [ -z "$upstream" ]; then
      echo -e "${YELLOW}Upstream yok, atlandi.${NC}"
      skip=$((skip+1))
      continue
    fi

    rel=$(branch_relation "HEAD" "$upstream")
    if [ -n "$rel" ]; then
      a=$(echo "$rel" | awk '{print $1}')
      g=$(echo "$rel" | awk '{print $2}')
      echo -e "Upstream: $upstream | ${GREEN}+$a${NC} / ${YELLOW}-$g${NC}"
    fi

    if git pull --rebase; then
      ok=$((ok+1))
    else
      echo -e "${RED}Senkron hatasi: $b${NC}"
      fail=$((fail+1))
      break
    fi
  done < <(git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)

  echo ""
  echo -e "Ozet: ${GREEN}$ok basarili${NC}, ${YELLOW}$skip atlandi${NC}, ${RED}$fail hata${NC}"
  if git checkout "$start_branch" >/dev/null 2>&1; then
    echo -e "${DIM}Baslangic branch'ine donuldu: $start_branch${NC}"
  else
    echo -e "${YELLOW}Baslangic branch'ine otomatik donulemedi: $start_branch${NC}"
  fi
}

menu() {
  MEVCUT_BRANCH=$(get_branch)
  DEGISIKLIK=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  clear
  echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║        ${BOLD}GIT YONETIM PANELI${NC}${CYAN}               ║${NC}"
  echo -e "${CYAN}╠══════════════════════════════════════════╣${NC}"
  echo -e "${CYAN}║${NC}  Repo    : ${BOLD}$(basename "$(pwd)")${NC}"
  echo -e "${CYAN}║${NC}  Branch  : ${GREEN}$MEVCUT_BRANCH${NC}"
  echo -e "${CYAN}║${NC}  Kullanici: $KULLANICI@$HOST"
  if [ "$DEGISIKLIK" -gt 0 ] 2>/dev/null; then
    echo -e "${CYAN}║${NC}  Bekleyen : ${YELLOW}$DEGISIKLIK degisiklik${NC}"
  else
    echo -e "${CYAN}║${NC}  Bekleyen : Temiz"
  fi
  ACTUAL_BRANCH=$(git branch --show-current 2>/dev/null)
  if [ -n "$ACTUAL_BRANCH" ]; then
    UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>/dev/null)
    if [ -n "$UPSTREAM" ]; then
      REL_UP=$(branch_relation "HEAD" "$UPSTREAM")
      if [ -n "$REL_UP" ]; then
        AHEAD_UP=$(echo "$REL_UP" | awk '{print $1}')
        BEHIND_UP=$(echo "$REL_UP" | awk '{print $2}')
        echo -e "${CYAN}║${NC}  Upstream : $UPSTREAM (${GREEN}$AHEAD_UP ileri${NC}, ${YELLOW}$BEHIND_UP geri${NC})"
      fi
    fi

    MAIN_REF=$(get_main_ref)
    if [ -n "$MAIN_REF" ] && [ "$ACTUAL_BRANCH" != "main" ]; then
      REL_MAIN=$(branch_relation "HEAD" "$MAIN_REF")
      if [ -n "$REL_MAIN" ]; then
        AHEAD_MAIN=$(echo "$REL_MAIN" | awk '{print $1}')
        BEHIND_MAIN=$(echo "$REL_MAIN" | awk '{print $2}')
        echo -e "${CYAN}║${NC}  Main fark: ${GREEN}$AHEAD_MAIN ileri${NC}, ${YELLOW}$BEHIND_MAIN geri${NC}"
        if [ "$BEHIND_MAIN" -gt 0 ] 2>/dev/null; then
          echo -e "${CYAN}║${NC}  ${RED}UYARI: $MAIN_REF dalindan $BEHIND_MAIN commit geridesin.${NC}"
          echo -e "${CYAN}║${NC}  ${DIM}(Hizli guncelle: 16)${NC}"
        fi
      fi
    fi
  fi
  echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}--- TEMEL ISLEMLER ---${NC}"
  echo -e "  ${GREEN}1${NC})  Kaydet ve Gonder    ${DIM}(commit & push)${NC}"
  echo -e "  ${GREEN}2${NC})  Guncelle             ${DIM}(pull)${NC}"
  echo -e "  ${GREEN}3${NC})  Durum Gor            ${DIM}(status)${NC}"
  echo -e "  ${GREEN}4${NC})  Gecmis Gor           ${DIM}(log)${NC}"
  echo -e "  ${GREEN}5${NC})  Fark Analizi         ${DIM}(calisma/main/dal)${NC}"
  echo ""
  echo -e "  ${BOLD}--- DALLANMA (BRANCH) ---${NC}"
  echo -e "  ${GREEN}6${NC})  Dal Degistir         ${DIM}(checkout)${NC}"
  echo -e "  ${GREEN}7${NC})  Yeni Dal Olustur     ${DIM}(new branch)${NC}"
  echo -e "  ${GREEN}8${NC})  Dal Sil              ${DIM}(delete branch)${NC}"
  echo -e "  ${GREEN}9${NC})  Dal Birlestir        ${DIM}(merge)${NC}"
  echo ""
  echo -e "  ${BOLD}--- DIGER ---${NC}"
  echo -e "  ${GREEN}10${NC}) Degisiklikleri Sakla  ${DIM}(stash)${NC}"
  echo -e "  ${GREEN}11${NC}) Saklananlar Geri Al  ${DIM}(stash pop)${NC}"
  echo -e "  ${GREEN}12${NC}) Geri Al              ${DIM}(restore)${NC}"
  echo -e "  ${GREEN}13${NC}) Etiket Olustur       ${DIM}(tag)${NC}"
  echo -e "  ${GREEN}14${NC}) Remote Bilgisi"
  echo -e "  ${GREEN}15${NC}) Remote Guncelle      ${DIM}(fetch)${NC}"
  echo -e "  ${GREEN}16${NC}) Senkron ve Guncelle  ${DIM}(main/upstream menusu)${NC}"
  echo -e "  ${GREEN}17${NC}) Korumali Oto Merge   ${DIM}(sifreli merge menusu)${NC}"
  echo ""
  echo -e "  ${YELLOW}?${NC})  Kullanim Kilavuzu"
  echo -e "  ${RED}0${NC})  Cikis"
  echo ""
  echo -n "  Secimin: "
}

kilavuz() {
  clear
  echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║        ${BOLD}KULLANIM KILAVUZU${NC}${CYAN}                ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${BOLD}TEMEL ISLEMLER${NC}"
  echo -e "─────────────────────────────────────────"
  echo -e "${GREEN}Kaydet ve Gonder (1):${NC}"
  echo "  Yaptgin degisiklikleri kaydeder ve GitHub'a gonderir."
  echo "  Commit mesaji yazabilirsin, bos birakirsan tarih+isim kullanilir."
  echo "  Ornek mesaj: 'Login ekrani eklendi | 2026-02-07 18:30:00 | kaan@MacBook'"
  echo ""
  echo -e "${GREEN}Guncelle (2):${NC}"
  echo "  GitHub'taki son degisiklikleri bilgisayarina indirir."
  echo "  Baska birisi degisiklik yaptiysa bu secenekle cek."
  echo ""
  echo -e "${GREEN}Durum Gor (3):${NC}"
  echo "  Hangi dosyalarin degistigini, eklendgini veya silindgini gosterir."
  echo ""
  echo -e "${GREEN}Gecmis Gor (4):${NC}"
  echo "  Son 15 commit'i listeler. Kim, ne zaman, ne degistirmis gorursun."
  echo ""
  echo -e "${GREEN}Fark Analizi (5):${NC}"
  echo "  Calisma alani, main veya secilen bir branch ile farklari gosterir."
  echo ""
  echo -e "${BOLD}DALLANMA (BRANCH)${NC}"
  echo -e "─────────────────────────────────────────"
  echo -e "${GREEN}Dal Degistir (6):${NC}"
  echo "  Baska bir dal (branch) uzerinde calismaya gecer."
  echo "  Ornek: 'main' dalindayken 'gelistirme' dalina gecis."
  echo ""
  echo -e "${GREEN}Yeni Dal Olustur (7):${NC}"
  echo "  Yeni bir calisma dali acar. Ana kodu bozmadan deney yapabilirsin."
  echo "  Ornek: 'yeni-ozellik' adinda bir dal acip orada calis."
  echo ""
  echo -e "${GREEN}Dal Sil (8):${NC}"
  echo "  Artik ihtiyac olmayan bir dali siler."
  echo "  Dikkat: Uzerinde oldugun dali silemezsin, once baska dala gec."
  echo ""
  echo -e "${GREEN}Dal Birlestir (9):${NC}"
  echo "  Baska bir daldaki degisiklikleri mevcut dalina aktarir."
  echo "  Ornek: 'yeni-ozellik' dalini 'main' ile birlestirmek."
  echo ""
  echo -e "${BOLD}DIGER${NC}"
  echo -e "─────────────────────────────────────────"
  echo -e "${GREEN}Degisiklikleri Sakla (10):${NC}"
  echo "  Yarim kalan isin varsa bir kenara koyar. Sonra geri alabilirsin."
  echo "  Ornek: Acil bir is cikti, mevcut calismayi sakla, hallettikten sonra geri al."
  echo ""
  echo -e "${GREEN}Saklananlar Geri Al (11):${NC}"
  echo "  Daha once sakladigin degisiklikleri geri getirir."
  echo ""
  echo -e "${GREEN}Geri Al (12):${NC}"
  echo "  Yaptgin degisiklikleri iptal eder. Tek dosya veya hepsini geri alabilirsin."
  echo "  Dikkat: Geri alinan degisiklikler kaybolur!"
  echo ""
  echo -e "${GREEN}Etiket Olustur (13):${NC}"
  echo "  Surum numarasi ekler. Ornek: v1.0.0, v2.1.0"
  echo ""
  echo -e "${GREEN}Remote Bilgisi (14):${NC}"
  echo "  Projenin bagli oldugu GitHub adresini gosterir."
  echo ""
  echo -e "${GREEN}Remote Guncelle (15):${NC}"
  echo "  GitHub'taki tum dal bilgilerini gunceller (dosyalari degistirmez)."
  echo ""
  echo -e "${GREEN}Senkron ve Guncelle (16):${NC}"
  echo "  Main ve upstream karsisinda kac commit ileri/geri oldugunu gosterir."
  echo "  Buradan pull --rebase / main rebase / main merge hizli yapabilirsin."
  echo ""
  echo -e "${GREEN}Korumali Oto Merge (17):${NC}"
  echo "  Uyari + sifre ister, sonra main veya secilen branch'leri otomatik merge eder."
  echo "  Ayrica tum local branch'leri main'e merge edip pushlama secenegi vardir."
  echo "  Istersen tum local branch'leri tek seferde senkronize de eder."
  echo ""
  echo -e "${BOLD}KISAYOLLAR${NC}"
  echo -e "─────────────────────────────────────────"
  echo "  E veya Enter  = Evet (onay sorularinda)"
  echo "  h             = Hayir (iptal)"
  echo "  0             = Ana menuye / Cikis"
  echo ""
  bekle
}

while true; do
  menu
  read -r secim

  case $secim in
    1)
      clear
      echo -e "${GREEN}=== KAYDET VE GONDER ===${NC}"
      echo ""
      git status -s
      echo ""
      DEGISIKLIK=$(git status --porcelain)
      if [ -z "$DEGISIKLIK" ]; then
        echo -e "${YELLOW}Kaydedilecek degisiklik yok.${NC}"
        bekle
        continue
      fi
      echo -e "Commit mesaji yazin ${DIM}(bos birakirsan tarih+isim kullanilir)${NC}:"
      read -r ACIKLAMA
      T=$(TARIH)
      if [ -z "$ACIKLAMA" ]; then
        MESAJ="$T | $KULLANICI@$HOST"
      else
        MESAJ="$ACIKLAMA | $T | $KULLANICI@$HOST"
      fi
      git add -A
      if ! git commit -m "$MESAJ"; then
        echo -e "${RED}Commit basarisiz oldu!${NC}"
        bekle
        continue
      fi
      echo ""
      echo -e "GitHub'a gonderilsin mi? ${DIM}[Enter=Evet / h=Hayir]${NC}"
      read -r PUSH
      if [ "$PUSH" != "h" ] && [ "$PUSH" != "H" ]; then
        if ! push_current_branch; then
          echo ""
          echo -e "${YELLOW}Push basarisiz. Remote ilerideyse 'pull --rebase' denensin mi? ${DIM}[Enter=Evet / h=Hayir]${NC}"
          read -r RETRY
          if [ "$RETRY" != "h" ] && [ "$RETRY" != "H" ]; then
            git pull --rebase && push_current_branch
          fi
        fi
      fi
      echo ""
      echo -e "${GREEN}Kaydedildi: $MESAJ${NC}"
      bekle
      ;;
    2)
      clear
      echo -e "${GREEN}=== GUNCELLE (PULL) ===${NC}"
      echo ""
      if ! git pull; then
        echo ""
        echo -e "${RED}Pull basarisiz oldu. Conflict olabilir, 'git status' ile kontrol edin.${NC}"
      fi
      bekle
      ;;
    3)
      clear
      echo -e "${GREEN}=== DURUM ===${NC}"
      echo ""
      git status
      bekle
      ;;
    4)
      clear
      echo -e "${GREEN}=== SON 15 COMMIT ===${NC}"
      echo ""
      git log --oneline --graph --decorate -15
      bekle
      ;;
    5)
      clear
      echo -e "${GREEN}=== FARK ANALIZI ===${NC}"
      echo ""
      echo "  1) Calisma alanini goster (unstaged/staged)"
      echo "  2) main ile farki goster"
      echo "  3) Secilen branch ile farki goster"
      echo ""
      echo -n "  Secimin: "
      read -r ALT_DIFF
      if [ "$ALT_DIFF" = "1" ]; then
        DIFF_STAT=$(git diff --stat 2>/dev/null)
        DIFF_CACHED=$(git diff --cached --stat 2>/dev/null)
        if [ -z "$DIFF_STAT" ] && [ -z "$DIFF_CACHED" ]; then
          echo -e "${YELLOW}Gosterilecek fark yok.${NC}"
        else
          if [ -n "$DIFF_STAT" ]; then
            echo "$DIFF_STAT"
          fi
          if [ -n "$DIFF_CACHED" ]; then
            echo -e "\n${DIM}(staged degisiklikler)${NC}"
            echo "$DIFF_CACHED"
          fi
          echo ""
          echo -e "Detayli gormek ister misin? ${DIM}[Enter=Evet / h=Hayir]${NC}"
          read -r DETAY
          if [ "$DETAY" != "h" ] && [ "$DETAY" != "H" ]; then
            git diff
            git diff --cached
          fi
        fi
      elif [ "$ALT_DIFF" = "2" ]; then
        MAIN_REF=$(get_main_ref)
        if [ -z "$MAIN_REF" ]; then
          echo -e "${RED}main dali bulunamadi (ne local ne origin/main).${NC}"
        else
          show_compare_report "$MAIN_REF" "$MAIN_REF"
        fi
      elif [ "$ALT_DIFF" = "3" ]; then
        git fetch --prune 2>/dev/null
        dal_listele
        dal_sec "  Karsilastirmak istedigin dal (numara): "
        if [ -n "$SECILEN_DAL" ]; then
          TARGET="$SECILEN_DAL"
          if is_remote_only "$SECILEN_DAL"; then
            TARGET="origin/$SECILEN_DAL"
          fi
          show_compare_report "$TARGET" "$TARGET"
        fi
      else
        echo -e "${YELLOW}Islem iptal edildi.${NC}"
      fi
      bekle
      ;;
    6)
      clear
      echo -e "${GREEN}=== DAL DEGISTIR ===${NC}"
      # Oncelikle remote bilgilerini guncelle
      git fetch --prune 2>/dev/null
      dal_listele
      dal_sec "  Gecmek istedigin dal (numara): "
      if [ -n "$SECILEN_DAL" ]; then
        if is_remote_only "$SECILEN_DAL"; then
          # Remote-only branch: tracking branch olarak olustur
          if git show-ref --verify --quiet "refs/heads/$SECILEN_DAL" 2>/dev/null; then
            git checkout "$SECILEN_DAL"
          else
            git checkout -b "$SECILEN_DAL" "origin/$SECILEN_DAL"
          fi
        else
          git checkout "$SECILEN_DAL"
        fi
        if [ $? -eq 0 ]; then
          echo -e "${GREEN}Dal degistirildi: $(get_branch)${NC}"
        else
          echo -e "${RED}Dal degistirilemedi!${NC}"
        fi
      fi
      bekle
      ;;
    7)
      clear
      echo -e "${GREEN}=== YENI DAL OLUSTUR ===${NC}"
      echo ""
      echo "Yeni dal adi:"
      read -r YENI
      if [ -n "$YENI" ]; then
        # Dal adi gecerlilik kontrolu
        if ! git check-ref-format --branch "$YENI" 2>/dev/null; then
          echo -e "${RED}Gecersiz dal adi! Bosluk ve ozel karakter kullanamazsin.${NC}"
        else
          if git show-ref --verify --quiet "refs/heads/$YENI" 2>/dev/null; then
            echo -e "${RED}Bu isimde bir dal zaten var!${NC}"
          else
            git checkout -b "$YENI"
            echo ""
            echo -e "GitHub'a gonderilsin mi? ${DIM}[Enter=Evet / h=Hayir]${NC}"
            read -r PUSH
            if [ "$PUSH" != "h" ] && [ "$PUSH" != "H" ]; then
              git push -u origin "$YENI"
            fi
          fi
        fi
      fi
      bekle
      ;;
    8)
      clear
      echo -e "${GREEN}=== DAL SIL ===${NC}"
      dal_listele
      dal_sec "  Silinecek dal (numara): "
      if [ -n "$SECILEN_DAL" ]; then
        MEVCUT_BRANCH=$(git branch --show-current 2>/dev/null)
        if [ "$SECILEN_DAL" = "$MEVCUT_BRANCH" ]; then
          echo -e "${RED}Uzerinde oldugun dali silemezsin! Once baska dala gec.${NC}"
        else
          echo -e "Emin misin? ${RED}'$SECILEN_DAL'${NC} silinecek ${DIM}[Enter=Evet / h=Hayir]${NC}"
          read -r ONAY
          if [ "$ONAY" != "h" ] && [ "$ONAY" != "H" ]; then
            if ! git branch -d "$SECILEN_DAL" 2>/dev/null; then
              echo -e "${YELLOW}Dal merge edilmemis. Yine de silinsin mi? ${DIM}[Enter=Evet / h=Hayir]${NC}"
              read -r ZORLA
              if [ "$ZORLA" != "h" ] && [ "$ZORLA" != "H" ]; then
                git branch -D "$SECILEN_DAL"
              fi
            fi
            echo -e "GitHub'tan da silinsin mi? ${DIM}[Enter=Evet / h=Hayir]${NC}"
            read -r REMOTE
            if [ "$REMOTE" != "h" ] && [ "$REMOTE" != "H" ]; then
              git push origin --delete "$SECILEN_DAL" 2>/dev/null
            fi
          fi
        fi
      fi
      bekle
      ;;
    9)
      clear
      MEVCUT_BRANCH=$(git branch --show-current 2>/dev/null)
      echo -e "${GREEN}=== DAL BIRLESTIR (MERGE) ===${NC}"
      echo ""
      if [ -z "$MEVCUT_BRANCH" ]; then
        echo -e "${RED}Detached HEAD durumundasin. Once bir dala gec (6).${NC}"
        bekle
        continue
      fi
      echo -e "Mevcut dal: ${BOLD}$MEVCUT_BRANCH${NC}"
      dal_listele
      dal_sec "  '$MEVCUT_BRANCH' uzerine hangi dali birlestirmek istiyorsun (numara): "
      if [ -n "$SECILEN_DAL" ]; then
        if [ "$SECILEN_DAL" = "$MEVCUT_BRANCH" ]; then
          echo -e "${RED}Bir dali kendisiyle birlestiremezsin!${NC}"
        else
          if ! git merge "$SECILEN_DAL"; then
            echo ""
            echo -e "${RED}Merge conflict olustu! Cozum secenekleri:${NC}"
            echo -e "  1) ${YELLOW}git status${NC} ile conflict olan dosyalari gor"
            echo -e "  2) Dosyalari duzenle, sonra ${YELLOW}git add . && git commit${NC}"
            echo -e "  3) Merge'i iptal etmek icin: ${YELLOW}git merge --abort${NC}"
          else
            echo -e "${GREEN}Merge basarili!${NC}"
          fi
        fi
      fi
      bekle
      ;;
    10)
      clear
      echo -e "${GREEN}=== DEGISIKLIKLERI SAKLA (STASH) ===${NC}"
      echo ""
      DEGISIKLIK=$(git status --porcelain 2>/dev/null)
      if [ -z "$DEGISIKLIK" ]; then
        echo -e "${YELLOW}Saklanacak degisiklik yok.${NC}"
        bekle
        continue
      fi
      echo -e "Stash mesaji ${DIM}(bos birakirsan otomatik)${NC}:"
      read -r STASH_MSG
      if [ -z "$STASH_MSG" ]; then
        git stash
      else
        git stash push -m "$STASH_MSG"
      fi
      echo -e "${GREEN}Degisiklikler saklandi.${NC}"
      bekle
      ;;
    11)
      clear
      echo -e "${GREEN}=== SAKLANANLARI GERI AL (STASH POP) ===${NC}"
      echo ""
      STASH_LIST=$(git stash list 2>/dev/null)
      if [ -z "$STASH_LIST" ]; then
        echo -e "${YELLOW}Saklanan degisiklik yok.${NC}"
        bekle
        continue
      fi
      echo "Saklanan degisiklikler:"
      echo "$STASH_LIST"
      echo ""
      echo -e "Geri alinsin mi? ${DIM}[Enter=Evet / h=Hayir]${NC}"
      read -r ONAY
      if [ "$ONAY" != "h" ] && [ "$ONAY" != "H" ]; then
        if ! git stash pop; then
          echo -e "${RED}Stash pop basarisiz! Conflict olabilir.${NC}"
        fi
      fi
      bekle
      ;;
    12)
      clear
      echo -e "${GREEN}=== GERI AL (RESTORE) ===${NC}"
      echo ""
      DEGISIKLIK=$(git status --porcelain 2>/dev/null)
      if [ -z "$DEGISIKLIK" ]; then
        echo -e "${YELLOW}Geri alinacak degisiklik yok.${NC}"
        bekle
        continue
      fi
      git status -s
      echo ""
      echo "  1) Tek dosya geri al"
      echo "  2) Tum degisiklikleri geri al"
      echo ""
      echo -n "  Secimin: "
      read -r ALT
      if [ "$ALT" = "1" ]; then
        echo "Dosya adi:"
        read -r DOSYA
        if [ -n "$DOSYA" ]; then
          if git checkout -- "$DOSYA" 2>/dev/null; then
            echo -e "${GREEN}Geri alindi: $DOSYA${NC}"
          else
            echo -e "${RED}Dosya bulunamadi veya geri alinamadi: $DOSYA${NC}"
          fi
        fi
      elif [ "$ALT" = "2" ]; then
        echo -e "${RED}UYARI: Tum degisiklikler kaybolacak!${NC}"
        echo "Emin misin? ('evet' yazin):"
        read -r ONAY
        if [ "$ONAY" = "evet" ]; then
          git checkout -- .
          git clean -fd 2>/dev/null
          echo -e "${GREEN}Tum degisiklikler geri alindi.${NC}"
        else
          echo "Iptal edildi."
        fi
      fi
      bekle
      ;;
    13)
      clear
      echo -e "${GREEN}=== ETIKET OLUSTUR (TAG) ===${NC}"
      echo ""
      echo "Mevcut etiketler:"
      TAGS=$(git tag 2>/dev/null)
      if [ -z "$TAGS" ]; then
        echo -e "  ${DIM}(henuz etiket yok)${NC}"
      else
        echo "$TAGS"
      fi
      echo ""
      echo "Etiket adi (orn: v1.0.0):"
      read -r TAG
      if [ -n "$TAG" ]; then
        # Ayni etiket var mi kontrol et
        if git tag -l "$TAG" | grep -q "^$TAG$"; then
          echo -e "${RED}Bu etiket zaten var!${NC}"
        else
          echo -e "Etiket mesaji ${DIM}(bos birakirsan basit etiket)${NC}:"
          read -r TAG_MSG
          if [ -z "$TAG_MSG" ]; then
            git tag "$TAG"
          else
            git tag -a "$TAG" -m "$TAG_MSG"
          fi
          echo -e "${GREEN}Etiket olusturuldu: $TAG${NC}"
          echo -e "GitHub'a gonderilsin mi? ${DIM}[Enter=Evet / h=Hayir]${NC}"
          read -r PUSH
          if [ "$PUSH" != "h" ] && [ "$PUSH" != "H" ]; then
            git push origin "$TAG"
          fi
        fi
      fi
      bekle
      ;;
    14)
      clear
      echo -e "${GREEN}=== REMOTE BILGISI ===${NC}"
      echo ""
      git remote -v
      bekle
      ;;
    15)
      clear
      echo -e "${GREEN}=== REMOTE GUNCELLE (FETCH) ===${NC}"
      echo ""
      git fetch --all --prune
      echo -e "${GREEN}Remote bilgileri guncellendi.${NC}"
      bekle
      ;;
    16)
      clear
      echo -e "${GREEN}=== SENKRON VE GUNCELLE MENUSU ===${NC}"
      echo ""
      git fetch --all --prune
      CURRENT=$(git branch --show-current 2>/dev/null)
      if [ -z "$CURRENT" ]; then
        echo -e "${RED}Detached HEAD durumundasin. Once bir dala gec (6).${NC}"
        bekle
        continue
      fi

      echo -e "Mevcut dal: ${BOLD}$CURRENT${NC}"
      UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>/dev/null)
      if [ -n "$UPSTREAM" ]; then
        REL_UP=$(branch_relation "HEAD" "$UPSTREAM")
        if [ -n "$REL_UP" ]; then
          AHEAD_UP=$(echo "$REL_UP" | awk '{print $1}')
          BEHIND_UP=$(echo "$REL_UP" | awk '{print $2}')
          echo -e "Upstream: $UPSTREAM (${GREEN}$AHEAD_UP ileri${NC}, ${YELLOW}$BEHIND_UP geri${NC})"
        fi
      else
        echo -e "${YELLOW}Bu dalin upstream'i tanimli degil.${NC}"
      fi

      MAIN_REF=$(get_main_ref)
      if [ -n "$MAIN_REF" ]; then
        REL_MAIN=$(branch_relation "HEAD" "$MAIN_REF")
        if [ -n "$REL_MAIN" ]; then
          AHEAD_MAIN=$(echo "$REL_MAIN" | awk '{print $1}')
          BEHIND_MAIN=$(echo "$REL_MAIN" | awk '{print $2}')
          echo -e "Main fark: $MAIN_REF (${GREEN}$AHEAD_MAIN ileri${NC}, ${YELLOW}$BEHIND_MAIN geri${NC})"
        fi
      fi

      echo ""
      echo "  1) Upstream'den pull --rebase"
      echo "  2) main degisikliklerini rebase et"
      echo "  3) main degisikliklerini merge et"
      echo "  4) Sadece fetch yenile"
      echo "  0) Geri"
      echo ""
      echo -n "  Secimin: "
      read -r SYNC_SECIM
      if [ "$SYNC_SECIM" = "1" ]; then
        git pull --rebase
      elif [ "$SYNC_SECIM" = "2" ]; then
        if [ -n "$MAIN_REF" ]; then
          git rebase "$MAIN_REF"
        else
          echo -e "${RED}main dali bulunamadi.${NC}"
        fi
      elif [ "$SYNC_SECIM" = "3" ]; then
        if [ -n "$MAIN_REF" ]; then
          git merge "$MAIN_REF"
        else
          echo -e "${RED}main dali bulunamadi.${NC}"
        fi
      elif [ "$SYNC_SECIM" = "4" ]; then
        git fetch --all --prune
      fi
      bekle
      ;;
    17)
      clear
      echo -e "${GREEN}=== KORUMALI OTOMATIK MERGE ===${NC}"
      echo ""
      if ! merge_password_guard; then
        bekle
        continue
      fi

      CURRENT=$(git branch --show-current 2>/dev/null)
      if [ -z "$CURRENT" ]; then
        echo -e "${RED}Detached HEAD durumundasin. Once bir dala gec (6).${NC}"
        bekle
        continue
      fi

      git fetch --all --prune
      echo -e "Mevcut dal: ${BOLD}$CURRENT${NC}"
      echo ""
      echo "  1) main'i mevcut dala merge et"
      echo "  2) Secilen tek dali mevcut dala merge et"
      echo "  3) Birden fazla dali sirayla merge et"
      echo "  4) Merge oncesi ileri/geri listesi (ad ile)"
      echo "  5) Tum local branch'leri main'e merge et + push"
      echo "  6) Tum local branch'leri senkronize et"
      echo "  0) Geri"
      echo ""
      echo -n "  Secimin: "
      read -r MSECIM

      if [ "$MSECIM" = "1" ]; then
        MAIN_REF=$(get_main_ref)
        if [ -z "$MAIN_REF" ]; then
          echo -e "${RED}main dali bulunamadi.${NC}"
        else
          merge_target_into_current "$MAIN_REF" "$MAIN_REF"
        fi
      elif [ "$MSECIM" = "2" ]; then
        dal_listele
        dal_sec "  Merge etmek istedigin dal (numara): "
        if [ -n "$SECILEN_DAL" ]; then
          TARGET="$SECILEN_DAL"
          if is_remote_only "$SECILEN_DAL"; then
            TARGET="origin/$SECILEN_DAL"
          fi
          merge_target_into_current "$TARGET" "$TARGET"
        fi
      elif [ "$MSECIM" = "3" ]; then
        dal_listele
        echo "Virgulle numara gir (orn: 2,4,5):"
        read -r COKLU
        if [ -n "$COKLU" ]; then
          IFS=',' read -r -a LISTE <<< "$COKLU"
          for raw in "${LISTE[@]}"; do
            idx=$(echo "$raw" | tr -d ' ')
            if [ -z "$idx" ] || ! [[ "$idx" =~ ^[0-9]+$ ]] || [ "$idx" -lt 1 ] || [ "$idx" -gt "${#TUM_DALLAR[@]}" ]; then
              echo -e "${YELLOW}Atlandi (gecersiz secim): $raw${NC}"
              continue
            fi
            pick="${TUM_DALLAR[$((idx-1))]}"
            target="$pick"
            if is_remote_only "$pick"; then
              target="origin/$pick"
            fi
            merge_target_into_current "$target" "$target"
            if [ $? -ne 0 ]; then
              echo -e "${YELLOW}Sirali merge durduruldu.${NC}"
              break
            fi
          done
        fi
      elif [ "$MSECIM" = "4" ]; then
        show_merge_precheck_list
      elif [ "$MSECIM" = "5" ]; then
        merge_all_into_main_and_push
      elif [ "$MSECIM" = "6" ]; then
        sync_all_local_branches
      fi
      bekle
      ;;
    "?")
      kilavuz
      ;;
    0)
      echo ""
      echo "Gorusuruz!"
      exit 0
      ;;
    *)
      echo -e "${RED}Gecersiz secim!${NC}"
      bekle
      ;;
  esac
done
