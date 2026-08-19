// ============================================================
//  RenderTraceTweak - 追踪 scale setter 调用点 (Dopamine tweak)
//  hook 微型 setter (STR W<x>,[X0,#0x50/0x54]; RET) 记录调用点+值
//  走 ellekit/substrate 框架, 不直接改代码页, 不受 CS 限制
// ============================================================
#import <substrate.h>
#import <mach-o/dyld.h>
#import <stdio.h>
#import <stdarg.h>
#import <string.h>
#import <unistd.h>
#import <fcntl.h>
#import <stdlib.h>

static uint64_t g_slide = 0;
static char g_log[131072];
static int g_len = 0;
static char g_path[512];

static void tlog(const char *fmt, ...) {
    if (g_len >= 131000) return;
    va_list ap; va_start(ap, fmt);
    g_len += vsnprintf(g_log + g_len, 131072 - g_len, fmt, ap);
    va_end(ap);
    if (g_path[0]) {
        int fd = open(g_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd >= 0) { write(fd, g_log, g_len); close(fd); }
    }
}

// ---- 候选 setter (文件偏移 = vaddr - 0x100000000) ----
// 0xb8cc  : STR W2,[X0,#0x50]  -> 值在 w2 (x2 低32位)   scaleX 候选
// 0x1ca6cc: STR W1,[X0,#0x54]  -> 值在 w1 (x1 低32位)   scaleY 候选
static void (*orig_sx50a)(uint64_t, uint64_t, uint64_t);
static void repl_sx50a(uint64_t x0, uint64_t x1, uint64_t x2) {
    uint32_t val = (uint32_t)x2;
    uintptr_t lr = (uintptr_t)__builtin_return_address(0);
    uint64_t off = (uint64_t)(lr - g_slide - 0x100000000ULL);
    tlog("[RT] sX_50_a file=0x%llx val=0x%08x this=0x%llx\n", off, val, x0);
    if (orig_sx50a) orig_sx50a(x0, x1, x2);
}

static void (*orig_sy54a)(uint64_t, uint64_t, uint64_t);
static void repl_sy54a(uint64_t x0, uint64_t x1, uint64_t x2) {
    uint32_t val = (uint32_t)x1;   // w1
    uintptr_t lr = (uintptr_t)__builtin_return_address(0);
    uint64_t off = (uint64_t)(lr - g_slide - 0x100000000ULL);
    tlog("[RT] sY_54_a file=0x%llx val=0x%08x this=0x%llx\n", off, val, x0);
    if (orig_sy54a) orig_sy54a(x0, x1, x2);
}

__attribute__((constructor))
static void init(void) {
    const char *home = getenv("HOME");
    if (home) snprintf(g_path, sizeof(g_path), "%s/Documents/render_trace.log", home);

    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *n = _dyld_get_image_name(i);
        if (n && strstr(n, "worldflipper")) {
            g_slide = _dyld_get_image_vmaddr_slide(i);
            break;
        }
    }

    tlog("[RT] RenderTraceTweak loaded slide=0x%llx pid=%d\n", g_slide, getpid());
    if (g_slide == 0) { tlog("[RT] ERROR: worldflipper not found\n"); return; }

    MSHookFunction((void *)(g_slide + 0x100000000ULL + 0xb8cc), (void *)repl_sx50a, (void **)&orig_sx50a);
    MSHookFunction((void *)(g_slide + 0x100000000ULL + 0x1ca6cc), (void *)repl_sy54a, (void **)&orig_sy54a);
    tlog("[RT] hooks installed\n");
}