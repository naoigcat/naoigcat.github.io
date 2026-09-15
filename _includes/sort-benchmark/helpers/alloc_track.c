#define _GNU_SOURCE
#include <dlfcn.h>
#include <malloc.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

static atomic_size_t live_bytes = 0;
static atomic_size_t peak_bytes = 0;

static void *(*real_malloc)(size_t) = NULL;
static void *(*real_calloc)(size_t, size_t) = NULL;
static void *(*real_realloc)(void *, size_t) = NULL;
static void (*real_free)(void *) = NULL;

static void init_reals(void) {
    if (real_malloc) {
        return;
    }
    real_malloc = (void *(*)(size_t))dlsym(RTLD_NEXT, "malloc");
    real_calloc = (void *(*)(size_t, size_t))dlsym(RTLD_NEXT, "calloc");
    real_realloc = (void *(*)(void *, size_t))dlsym(RTLD_NEXT, "realloc");
    real_free = (void (*)(void *))dlsym(RTLD_NEXT, "free");
}

static void record_alloc(size_t size) {
    size_t live = atomic_fetch_add(&live_bytes, size) + size;
    size_t peak = atomic_load(&peak_bytes);
    while (live > peak) {
        if (atomic_compare_exchange_weak(&peak_bytes, &peak, live)) {
            break;
        }
    }
}

void alloc_track_reset_peak(void) {
    atomic_store(&peak_bytes, atomic_load(&live_bytes));
}

size_t alloc_track_live(void) { return atomic_load(&live_bytes); }
size_t alloc_track_peak(void) { return atomic_load(&peak_bytes); }

void *malloc(size_t size) {
    init_reals();
    void *p = real_malloc(size);
    if (p) {
        record_alloc(malloc_usable_size(p));
    }
    return p;
}

void *calloc(size_t nmemb, size_t size) {
    init_reals();
    void *p = real_calloc(nmemb, size);
    if (p) {
        record_alloc(malloc_usable_size(p));
    }
    return p;
}

void *realloc(void *ptr, size_t size) {
    init_reals();
    size_t old_size = 0;
    if (ptr) {
        old_size = malloc_usable_size(ptr);
    }
    void *p = real_realloc(ptr, size);
    if (p) {
        atomic_fetch_sub(&live_bytes, old_size);
        record_alloc(malloc_usable_size(p));
    } else if (size == 0) {
        atomic_fetch_sub(&live_bytes, old_size);
    }
    return p;
}

void free(void *ptr) {
    init_reals();
    if (ptr) {
        atomic_fetch_sub(&live_bytes, malloc_usable_size(ptr));
        real_free(ptr);
    }
}
