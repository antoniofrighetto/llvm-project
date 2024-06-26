; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 4
; RUN: llc -mtriple=aarch64-linux-gnu -mattr=+sve -global-isel -aarch64-enable-gisel-sve=true < %s | FileCheck %s

define void @scalable_v16i8(ptr %l0, ptr %l1) {
; CHECK-LABEL: scalable_v16i8:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.b
; CHECK-NEXT:    ld1b { z0.b }, p0/z, [x0]
; CHECK-NEXT:    st1b { z0.b }, p0, [x1]
; CHECK-NEXT:    ret
  %l3 = load <vscale x 16 x i8>, ptr %l0, align 16
  store <vscale x 16 x i8> %l3, ptr %l1, align 16
  ret void
}

define void @scalable_v8i16(ptr %l0, ptr %l1) {
; CHECK-LABEL: scalable_v8i16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.h
; CHECK-NEXT:    ld1h { z0.h }, p0/z, [x0]
; CHECK-NEXT:    st1h { z0.h }, p0, [x1]
; CHECK-NEXT:    ret
  %l3 = load <vscale x 8 x i16>, ptr %l0, align 16
  store <vscale x 8 x i16> %l3, ptr %l1, align 16
  ret void
}

define void @scalable_v4i32(ptr %l0, ptr %l1) {
; CHECK-LABEL: scalable_v4i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.s
; CHECK-NEXT:    ld1w { z0.s }, p0/z, [x0]
; CHECK-NEXT:    st1w { z0.s }, p0, [x1]
; CHECK-NEXT:    ret
  %l3 = load <vscale x 4 x i32>, ptr %l0, align 16
  store <vscale x 4 x i32> %l3, ptr %l1, align 16
  ret void
}

define void @scalable_v2i64(ptr %l0, ptr %l1) {
; CHECK-LABEL: scalable_v2i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.d
; CHECK-NEXT:    ld1d { z0.d }, p0/z, [x0]
; CHECK-NEXT:    st1d { z0.d }, p0, [x1]
; CHECK-NEXT:    ret
  %l3 = load <vscale x 2 x i64>, ptr %l0, align 16
  store <vscale x 2 x i64> %l3, ptr %l1, align 16
  ret void
}
