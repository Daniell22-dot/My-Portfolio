---
title: "PHP2Shell: Critical Remote Code Execution in the PHP Engine"
subtitle: "Threat Advisory and Remediation Guide — CVE-2026-109618 / CVE-2026-109619"
author: "Bulwark Security Research"
date: "26 October 2026"
version: "1.0"
classification: "Public / TLP:CLEAR"
---

# PHP2Shell: Critical Remote Code Execution in the PHP Engine

**Report date:** 26 October 2026  
**Advisory window:** 20–26 October 2026  
**Severity:** Critical — CVSS v4.0 **9.2** (`CVSS:4.0/AV:N/AC:H/AT:P/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N`)  
**Status:** Patches available. Active mass exploitation attempts in progress.  
**Affected:** Every PHP deployment that processes HTTP requests — Apache `mod_php`, PHP-FPM, `php-cgi`, FrankenPHP, LiteSpeed.

---

## 1. Executive Summary

On **20–21 October 2026**, the PHP project published emergency security releases fixing two critical remote code execution (RCE) vulnerabilities in the PHP engine itself, collectively tracked as **"PHP2Shell"**:

- **CVE-2026-109618** — RCE via **OOM (out-of-memory) corruption**
- **CVE-2026-109619** — RCE via **stale global state**

Both are **pre-authentication** and **application-agnostic**: the flaw is in PHP's request lifecycle and memory management, not in any particular framework or CMS. Any web-reachable PHP process is potentially exploitable regardless of the application it serves. Because the vulnerable logic has existed in the PHP core since at least **PHP 5.4**, the unpatched install base is enormous.

Patches shipped on **21 October 2026 at 13:30 UTC** in:

| PHP branch | Fixed version |
|---|---|
| 8.5 | **8.5.12** |
| 8.4 | **8.4.27** |
| 8.3 | **8.3.36** |
| 8.2 | **8.2.35** |

A related but lower-urgency advisory, **CVE-2026-115560**, was published after the PHP2Shell patches and covers a session upload-progress / `serialize_handler` issue (details in §4.3).

**Exploitation activity is intense.** Attempts against internet-facing PHP reached **millions within roughly 45 minutes** of public disclosure. Mirai-family botnets ("Potassium" variants) are scanning and attempting both CVEs. As of **23 October 2026**, CISA reported **no confirmed successful exploitation**, and Wordfence/Previdian had **not confirmed code execution**; however, VulnCheck published a **working ASLR bypass** lowering the practical bar. Censys counted roughly **34.4 million vulnerable services**, of which about **272,000 hosts** run a supported branch that can simply be patched.

> **Bottom line:** patch now. Treat any unpatched, internet-facing PHP host as compromised-risk. Where patching cannot be immediate, apply the configuration mitigations in §8 (disable `session.upload_progress`, avoid `mod_php`, harden `memory_limit` handling) and front the service with WAF rules.

---

## 2. Timeline

| Date (2026) | Event |
|---|---|
| ~17 Oct | Amazon honeypot records first probing attempts — **four days before public disclosure** (suggests pre-disclosure knowledge or opportunistic fuzzing). |
| 20 Oct | Initial coordinated disclosure activity begins; advisories appear. |
| 21 Oct, 13:30 UTC | PHP **8.5.12 / 8.4.27 / 8.3.36 / 8.2.35** released. |
| 21 Oct | CISA publishes alert urging immediate patching. CERT-EU (2026-018), NCSC-NZ, CSA Singapore (al-2026-151) follow. |
| 21–22 Oct | Exploit attempts hit **millions within ~45 minutes**; Cloudflare observes tens of thousands rising to millions of malicious requests. |
| 22 Oct | VulnCheck discloses **ASLR bypass** technique; Mirai/Potassium botnet scanning observed. |
| 23 Oct | CISA: **no confirmed successful exploitation** yet; Wordfence/Previdian report no confirmed code execution. |
| 24–26 Oct | Continued scanning; third advisory **CVE-2026-115560** surfaces (session upload progress / `serialize_handler`). |

---

## 3. Technical Analysis — CVE-2026-109618 (OOM Corruption)

### 3.1 Root cause

PHP uses `longjmp()` to abort execution when the memory limit is exceeded during request processing. The abort path tears down partially-initialized request structures (**CWE-416 use-after-free**, **CWE-824 access of uninitialized pointer**, **CWE-755 improper handling of exceptional conditions**). Under specific multipart upload and memory-exhaustion sequences, some of those structures remain in an inconsistent state.

The corruption is not itself code execution. An attacker who can shape memory layout (heap grooming) can turn the corrupted state into a controllable out-of-bounds write primitive, then redirect execution.

### 3.2 Why it is reachable from the network

Multipart request parsing is performed by the engine before application code runs, and `memory_limit` enforcement is an engine concern. An attacker can deliberately drive a request into OOM with oversized or malformed multipart bodies, triggering the `longjmp()` abort path at a chosen point. No authentication, no application-specific endpoint, and no user interaction are required.

### 3.3 SAPI susceptibility

The impact depends on how the Server API (SAPI) handles the abort:

- **Apache `mod_php` — highest risk.** The `mod_php` shutdown path is unconditional and runs inside the Apache worker process; corrupted state can persist and be reused. This is the worst-case configuration.
- **PHP-FPM — moderated.** The worker exits on the abort, which limits state reuse, but the corruption primitive is still reachable and the process death itself is a denial-of-service vector.
- **`php-cgi`, FrankenPHP, LiteSpeed (LSAPI)** — affected; exploitability varies with process-shutdown semantics.

### 3.4 Patch approach

The fixes make the OOM abort path **state-safe**: structures are fully initialized or explicitly invalidated before `longjmp()`, and the shutdown sequence no longer walks partially-built state. The emergency releases shipped the fix across all supported branches to reduce the unpatched tail.

---

## 4. Technical Analysis — CVE-2026-109619 (Stale Global State)

### 4.1 Root cause

PHP maintains request-scoped global state. After certain error/exception paths — notably **fatal-error backtraces** and **session upload-progress** handling — a global pointer can continue to reference memory that has already been freed at the end of the request (**CWE-416 use-after-free**). A subsequent request in the same process can then operate on that stale pointer.

### 4.2 Producer / consumer model

The advisory describes a **producer** step that frees or invalidates memory while leaving a dangling global reference, and a **consumer** step that dereferences it. When the two occur in the same long-lived worker process, an attacker can influence the freed contents and convert the dangling pointer into controlled execution.

- **HTTP path confirmed:** `mod_php` RCE is validated; PHP-FPM is validated as reachable.
- **`phpdbg` / INI-diagnostics vector:** reachable only with **local shell access**, not over HTTP — lower priority.
- **Fatal-error backtrace (`fatal_error_backtraces`)**: an alternative in-process trigger, relevant where that diagnostic is enabled.
- **Session upload progress**: a documented in-process trigger (also the subject of a follow-up advisory, see §4.3).

### 4.3 CVE-2026-115560 (follow-up advisory)

Published after the main patches, this covers unsafe interaction between **session upload-progress** and changes to the runtime **`serialize_handler`**. It is rated lower and is *unlikely* to be exploitable in most configurations, but it reinforces the same theme: session upload-progress is a recurring hazard and should be disabled unless explicitly needed.

---

## 5. Vulnerability Matrix

| CVE | Type | Attack vector | Pre-auth | Confidence / status | Notes |
|---|---|---|---|---|---|
| **CVE-2026-109618** | OOM corruption / RCE | Network (HTTP multipart + memory exhaustion) | Yes | Validated; mass attempts | `mod_php` worst case; `longjmp()` abort path |
| **CVE-2026-109619** | Stale global state / RCE | Network (error paths, session upload progress) | Yes | `mod_php` RCE confirmed; FPM reachability validated | Producer/consumer dangling pointer |
| **CVE-2026-115560** | Session upload progress + runtime `serialize_handler` | Network / local | Depends on app | Informational; unlikely | Post-patch advisory |

**Affected versions:** all PHP releases from **5.4** through the fixed versions above. There is no supported branch older than 8.2; older branches are end-of-life and will **not** receive official patches — they must be upgraded or virtual-patched.

---

## 6. Exposure and Exploitation

- **Scale:** ~**34.4 million** vulnerable services observed (Censys); ~**272,000** hosts on a supported branch are directly patchable.
- **Attempt volume:** millions of requests within ~45 minutes of disclosure; Cloudflare saw a jump from tens of thousands to millions.
- **Actors:** Mirai-family botnets (Potassium variants) performing automated double-CVE attempts; opportunistic mass scanning by many unrelated actors.
- **Honeypot pre-signal:** Amazon recorded attempts on ~17 October, before public disclosure.
- **Practical barrier:** an attacker must win a **race / heap-grooming** problem, which is why confirmed RCE has lagged the attempt volume. **VulnCheck's ASLR bypass** meaningfully lowers this barrier — do not assume "no confirmed RCE yet" means safe.
- **Visible side effects:** government sites taken offline "out of caution"; widespread WAF blocking.

### 6.1 Representative indicators (for hunting, not blocklisting)

Public reporting has cited scanning/attempt traffic including `45.148.10.0/24` and `91.92.240.0/24`, and Mirai-linked infrastructure. **IP indicators are low-fidelity** — prefer behavioural detection (§7).

---

## 7. Detection and Hunting

### 7.1 High-value log signals

- PHP worker crashes / `SIGSEGV` / `SIGABRT` correlated with **multipart uploads** or **`memory_limit`** errors.
- Repeated `Allowed memory size ... exhausted` immediately followed by worker death.
- Fatal errors whose backtraces reference session upload-progress internals.
- Apache error log: `child pid ... exit signal Segmentation fault (11)` on `mod_php`.
- FPM log: `WARNING: [pool www] child ... exited on signal 11 (SIGSEGV)`.
- Sudden spike in `POST` requests with very large or malformed `multipart/form-data` bodies.

### 7.2 Post-exploitation hunt

- Unexpected child processes of the web/PHP worker (`sh`, `bash`, `cmd.exe`, `powershell`, `curl`, `wget`, `nc`).
- Newly written files in web roots (`*.php` with encoded/obfuscated payloads, webshell signatures).
- Outbound connections from web workers to unfamiliar hosts.
- Modifications to `php.ini`, `.htaccess`, FPM pool config, or cron/`systemd` units.
- Session files with anomalous size/content (upload-progress abuse).

### 7.3 Suggested detection logic (pseudo-SIGMA)

```yaml
title: PHP worker crash following memory exhaustion (PHP2Shell signal)
logsource:
  product: linux
  service: php-fpm
detection:
  oom:
    - 'Allowed memory size'
    - 'exited on signal 11'
    - 'exit signal Segmentation fault'
  multipart:
    - 'multipart/form-data'
  timeframe: 2m
  condition: oom and multipart
level: high
```

### 7.4 WAF strategy

Block or challenge requests that combine large multipart bodies with abnormal part counts/filenames, and rate-limit requests designed to exhaust memory. WAF is **compensating**, not a fix.

---

## 8. Mitigation and Remediation

### 8.1 Priority order

1. **Patch immediately** to 8.5.12 / 8.4.27 / 8.3.36 / 8.2.35 (or later).
2. **Inventory embedded PHP**: appliances, containers, vendor bundles, WordPress/Laravel/Drupal images, CI runners, and forgotten staging hosts. Rebuild images from patched bases.
3. **Hunt** for post-exploitation indicators (§7) on any host that was internet-facing and unpatched between 21 and patch time.
4. **Rotate** application secrets, database credentials, and API keys for any host that was exposed while vulnerable.
5. **EOL branches**: upgrade now; no official patches will arrive for < 8.2.

### 8.2 Temporary hardening (until patch is deployable)

Disable session upload progress (removes a documented trigger for the 109619 class and closes the 115560 surface):

```ini
; php.ini
session.upload_progress.enabled = Off
```

Move off `mod_php` where feasible (use PHP-FPM behind a reverse proxy) to reduce worst-case state reuse; keep workers short-lived. Do **not** rely on raising `memory_limit` — it does not remove the abort path, it only changes when it fires.

### 8.3 Verification

```bash
php -v            # expect 8.5.12 / 8.4.27 / 8.3.36 / 8.2.35 or later
php -i | grep -i "session.upload_progress"
```

Re-check containers and load balancers, not just the host CLI.

---

## 9. Implications for Bulwark / SENTINEL

The repository contains a detection rule at `src/Core/Web/Rules/Php2ShellRule.cs` (Id `PHP2Shell`). An earlier draft of this report and the first version of the rule contained several inaccuracies. Both have been corrected in this revision:

| Issue (corrected in this revision) | Correction applied |
|---|---|
| Rule inferred `session.upload_progress` from a `PHPSESSID` cookie | Removed. `PHPSESSID` is a normal session cookie and says nothing about upload-progress being enabled; verify it via config/`php -i`. |
| Rule framed the issue as an **OPcache type-confusion** | Removed. The actual issues are OOM/`longjmp` state corruption and a stale-global-pointer use-after-free. |
| Earlier draft named fabricated model/company details ("Gemini 4 Argon", "GPT-5.6 Sol", "Wiz Atlas", "Quarkslab") | Removed. Correct credit is **Calif (lcfr-hax), OpenAI (amyb-oai), and Wiz Research (sagitzadik-wiz, tomash-areion)**. |
| No coverage of **CVE-2026-115560** | Added as an informational, lower-confidence issue. |
| Version logic used a single `<= 8.5.11` ceiling | Replaced with per-branch checks (8.2.35 / 8.3.36 / 8.4.27 / 8.5.12), so patched releases are no longer flagged. |
| Fix templates recommended `memory_limit = -1` and `opcache.enable = 0` | Removed. Those do not fix the flaw and `memory_limit = -1` weakens DoS resistance; templates now recommend patching plus optional `session.upload_progress` hardening. |

**Remaining recommended improvements**

1. Detect `mod_php` (highest-risk SAPI) and recommend PHP-FPM.
2. Correlate web-worker crashes with multipart/OOM for a live-exploitation signal (see §7.1).
3. Keep CVE references and remediation links in the finding output so operators can act.
4. Add configuration-level checks where the scanner has host access (`session.upload_progress`, `fatal_error_backtraces`).

### 9.1 Related observation — `Sentinel.Core.dll` antivirus false positive

Defender/heuristics have flagged the unsigned `Sentinel.Core.dll` as a trojan. This is a **false positive** consistent with its behaviour: an unsigned binary that performs process enumeration, ETW/telemetry collection, network inspection, and self-updating. Installed hash `76E0C1445D3E0CD81681C5E5FF2D91261DE8C95206D7C19EE4BFC9B927792E80` (731,648 bytes) vs. the local dev build `7DC6AC3EFA02F4FB569334ADBBEC87B1EFF6CA1C8FD2CF0D4D9C1080EB78DFEB` — the mismatch is expected (different build), not evidence of tampering.

**Actions:** (a) **Authenticode-sign** release binaries and timestamp them; (b) submit the signed DLL to Microsoft/AV vendors for whitelisting; (c) document hashes per release; (d) confirm the installed copy matches a signed release, not a developer build. Note also that the `SENTINEL` service was still running after the reported uninstall — verify removal and reinstall from the signed 4.0.1 installer.

---

## 10. References

1. CISA alert (21 Oct 2026): https://www.cisa.gov/news-events/alerts/2026/10/21/critical-vulnerabilities-php-require-immediate-patching
2. CERT-EU Security Advisory 2026-018: https://cert.europa.eu/publications/security-advisories/2026-018
3. NCSC-NZ alert: https://www.ncsc.govt.nz/alerts/cve-2026-109618-and-cve-2026-109619-affecting-php/
4. CSA Singapore al-2026-151: https://www.csa.gov.sg/alerts-and-advisories/alerts/al-2026-151/
5. CVE-2026-109618: https://www.cve.org/CVERecord?id=CVE-2026-109618
6. CVE-2026-109619: https://www.cve.org/CVERecord?id=CVE-2026-109619
7. GitHub advisory GHSA-w8hw-w9fx-j79w (OOM corruption): https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w
8. GitHub advisory GHSA-6wmf-4rv5-p3rp (stale global state): https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp
9. NCSC-NL PHP2Shell repository: https://github.com/NCSC-NL/php2shell
10. The Hacker News — exploit attempts hit millions: https://thehackernews.com/2026/10/php2shell-exploit-attempts-hit-millions.html
11. BleepingComputer — emergency patches: https://www.bleepingcomputer.com/news/security/php-ships-emergency-patches-for-critical-php2shell-flaws

---

*Prepared by Bulwark Security Research. Indicators and exploitation statistics reflect public reporting through 26 October 2026 and may change. Verify patches against upstream PHP release notes before deployment.*
