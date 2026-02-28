# C64 IRQ Workflow (KickAssembler + VICE)

This workflow documents the exact steps to:
1. write `irq.asm`,
2. compile it to `irq.prg`,
3. run it in VICE,
4. take remote-monitor screenshots.

---

## 1) Write the ASM program

Create `irq.asm` in:

`C:\git\c64\c64_asm\c64_llm_workflow\irq.asm`

Program goal: install a raster IRQ that increments border color (`$D020`) each interrupt.

---

## 2) Compile ASM to PRG with KickAssembler

KickAssembler jar path:

`c:\git\c64\c64_assemblers\kickass\kickass.jar`

Compile command:

```powershell
java -jar c:\git\c64\c64_assemblers\kickass\kickass.jar C:\git\c64\c64_asm\c64_llm_workflow\irq.asm
```

Expected outputs in the same folder:
- `irq.prg`
- `irq.sym`

---

## 3) Start program in VICE

VICE executable:

`C:\git\c64\c64_tools\vice\bin\x64sc.exe`

Run command:

```powershell
C:\git\c64\c64_tools\vice\bin\x64sc.exe C:\git\c64\c64_asm\c64_llm_workflow\irq.prg
```

---

## 4) Take screenshots via VICE remote monitor (no `-exitscreenshot`)

Start VICE with remote monitor enabled:

```powershell
C:\git\c64\c64_tools\vice\bin\x64sc.exe -remotemonitor -remotemonitoraddress 127.0.0.1:6502 C:\git\c64\c64_asm\c64_llm_workflow\irq.prg
```

Connect to monitor socket (`127.0.0.1:6502`) and send monitor commands:

```text
screenshot "C:\git\c64\c64_asm\c64_llm_workflow\irq_remote_screenshot_1.png" 2
x
(wait 1 second)
screenshot "C:\git\c64\c64_asm\c64_llm_workflow\irq_remote_screenshot_2.png" 2
x
(wait 1 second)
screenshot "C:\git\c64\c64_asm\c64_llm_workflow\irq_remote_screenshot_3.png" 2
x
(wait 1 second)
screenshot "C:\git\c64\c64_asm\c64_llm_workflow\irq_remote_screenshot_4.png" 2
x
(wait 1 second)
screenshot "C:\git\c64\c64_asm\c64_llm_workflow\irq_remote_screenshot_5.png" 2
x
(wait 1 second)
quit
```

### Important behavior

- `screenshot` is a **monitor command**, so execution is paused while monitor is active.
- To keep animation running between captures, send `x` (or `exit`) after each screenshot.
- Use PNG format with trailing `2` in command.
- Finish with `quit` to close emulator cleanly.

---

## 5) Quick end-to-end command sequence

```powershell
# compile
java -jar c:\git\c64\c64_assemblers\kickass\kickass.jar C:\git\c64\c64_asm\c64_llm_workflow\irq.asm

# run with remote monitor
C:\git\c64\c64_tools\vice\bin\x64sc.exe -remotemonitor -remotemonitoraddress 127.0.0.1:6502 C:\git\c64\c64_asm\c64_llm_workflow\irq.prg
```

Then send the monitor command sequence from section 4.
