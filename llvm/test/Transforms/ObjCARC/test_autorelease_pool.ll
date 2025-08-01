; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 5
; Test for autorelease pool optimizations
; RUN: opt -passes=objc-arc < %s -S | FileCheck %s

declare ptr @llvm.objc.autoreleasePoolPush()
declare void @llvm.objc.autoreleasePoolPop(ptr)
declare ptr @llvm.objc.autorelease(ptr)
declare ptr @llvm.objc.retain(ptr)
declare ptr @create_object()
declare void @use_object(ptr)
declare ptr @object_with_thing()
declare void @opaque_callee()

; Empty autorelease pool should be eliminated
define void @test_empty_pool() {
; CHECK-LABEL: define void @test_empty_pool() {
; CHECK-NEXT:    ret void
;
  %pool = call ptr @llvm.objc.autoreleasePoolPush()
  call void @llvm.objc.autoreleasePoolPop(ptr %pool)
  ret void
}

; Pool with only release should be removed
define void @test_autorelease_to_release() {
; CHECK-LABEL: define void @test_autorelease_to_release() {
; CHECK-NEXT:    [[OBJ:%.*]] = call ptr @create_object()
; CHECK-NEXT:    call void @llvm.objc.release(ptr [[OBJ]]) #[[ATTR0:[0-9]+]], !clang.imprecise_release [[META0:![0-9]+]]
; CHECK-NEXT:    ret void
;
  %obj = call ptr @create_object()
  %pool = call ptr @llvm.objc.autoreleasePoolPush()
  call ptr @llvm.objc.autorelease(ptr %obj)
  call void @llvm.objc.autoreleasePoolPop(ptr %pool)
  ret void
}

; Pool with autoreleases should not be optimized
define void @test_multiple_autoreleases() {
; CHECK-LABEL: define void @test_multiple_autoreleases() {
; CHECK-NEXT:    [[OBJ1:%.*]] = call ptr @create_object()
; CHECK-NEXT:    [[OBJ2:%.*]] = call ptr @create_object()
; CHECK-NEXT:    [[POOL:%.*]] = call ptr @llvm.objc.autoreleasePoolPush() #[[ATTR0]]
; CHECK-NEXT:    call void @use_object(ptr [[OBJ1]])
; CHECK-NEXT:    [[TMP1:%.*]] = call ptr @llvm.objc.autorelease(ptr [[OBJ1]]) #[[ATTR0]]
; CHECK-NEXT:    call void @use_object(ptr [[OBJ2]])
; CHECK-NEXT:    [[TMP2:%.*]] = call ptr @llvm.objc.autorelease(ptr [[OBJ2]]) #[[ATTR0]]
; CHECK-NEXT:    call void @llvm.objc.autoreleasePoolPop(ptr [[POOL]]) #[[ATTR0]]
; CHECK-NEXT:    ret void
;
  %obj1 = call ptr @create_object()
  %obj2 = call ptr @create_object()
  %pool = call ptr @llvm.objc.autoreleasePoolPush()
  call void @use_object(ptr %obj1)
  call ptr @llvm.objc.autorelease(ptr %obj1)
  call void @use_object(ptr %obj2)
  call ptr @llvm.objc.autorelease(ptr %obj2)
  call void @llvm.objc.autoreleasePoolPop(ptr %pool)
  ret void
}

; Pool with calls should not be optimized
define void @test_calls() {
; CHECK-LABEL: define void @test_calls() {
; CHECK-NEXT:    [[POOL:%.*]] = call ptr @llvm.objc.autoreleasePoolPush() #[[ATTR0]]
; CHECK-NEXT:    [[OBJ1:%.*]] = call ptr @object_with_thing()
; CHECK-NEXT:    call void @use_object(ptr [[OBJ1]])
; CHECK-NEXT:    call void @llvm.objc.autoreleasePoolPop(ptr [[POOL]]) #[[ATTR0]]
; CHECK-NEXT:    ret void
;
  %pool = call ptr @llvm.objc.autoreleasePoolPush()
  %obj1 = call ptr @object_with_thing()
  call void @use_object(ptr %obj1)
  call void @llvm.objc.autoreleasePoolPop(ptr %pool)
  ret void
}

; Pool with opaque call should not be optimized
define void @test_opaque_call() {
; CHECK-LABEL: define void @test_opaque_call() {
; CHECK-NEXT:    [[POOL:%.*]] = call ptr @llvm.objc.autoreleasePoolPush() #[[ATTR0]]
; CHECK-NEXT:    call void @opaque_callee()
; CHECK-NEXT:    call void @llvm.objc.autoreleasePoolPop(ptr [[POOL]]) #[[ATTR0]]
; CHECK-NEXT:    ret void
;
  %pool = call ptr @llvm.objc.autoreleasePoolPush()
  call void @opaque_callee()
  call void @llvm.objc.autoreleasePoolPop(ptr %pool)
  ret void
}

; Nested empty pools should be eliminated
define void @test_nested_empty_pools() {
; CHECK-LABEL: define void @test_nested_empty_pools() {
; CHECK-NEXT:    ret void
;
  %pool1 = call ptr @llvm.objc.autoreleasePoolPush()
  %pool2 = call ptr @llvm.objc.autoreleasePoolPush()
  call void @llvm.objc.autoreleasePoolPop(ptr %pool2)
  call void @llvm.objc.autoreleasePoolPop(ptr %pool1)
  ret void
}

; Empty pool with cast should be eliminated
define void @test_empty_pool_with_cast() {
; CHECK-LABEL: define void @test_empty_pool_with_cast() {
; CHECK-NEXT:    [[CAST:%.*]] = bitcast ptr poison to ptr
; CHECK-NEXT:    ret void
;
  %pool = call ptr @llvm.objc.autoreleasePoolPush()
  %cast = bitcast ptr %pool to ptr
  call void @llvm.objc.autoreleasePoolPop(ptr %cast)
  ret void
}

; Autorelease shadowing - autorelease in inner pool doesn't prevent outer optimization
define void @test_autorelease_shadowing_basic() {
; CHECK-LABEL: define void @test_autorelease_shadowing_basic() {
; CHECK-NEXT:    [[OBJ:%.*]] = call ptr @create_object()
; CHECK-NEXT:    call void @llvm.objc.release(ptr [[OBJ]]) #[[ATTR0]], !clang.imprecise_release [[META0]]
; CHECK-NEXT:    ret void
;
  %obj = call ptr @create_object()
  %outer_pool = call ptr @llvm.objc.autoreleasePoolPush()

  ; Inner pool with autorelease - this should be shadowed
  %inner_pool = call ptr @llvm.objc.autoreleasePoolPush()
  call ptr @llvm.objc.autorelease(ptr %obj)
  call void @llvm.objc.autoreleasePoolPop(ptr %inner_pool)

  call void @llvm.objc.autoreleasePoolPop(ptr %outer_pool)
  ret void
}

; Multiple nested levels with shadowing
define void @test_multiple_nested_shadowing() {
; CHECK-LABEL: define void @test_multiple_nested_shadowing() {
; CHECK-NEXT:    [[OBJ1:%.*]] = call ptr @create_object()
; CHECK-NEXT:    [[OBJ2:%.*]] = call ptr @create_object()
; CHECK-NEXT:    call void @llvm.objc.release(ptr [[OBJ1]]) #[[ATTR0]], !clang.imprecise_release [[META0]]
; CHECK-NEXT:    call void @llvm.objc.release(ptr [[OBJ2]]) #[[ATTR0]], !clang.imprecise_release [[META0]]
; CHECK-NEXT:    ret void
;
  %obj1 = call ptr @create_object()
  %obj2 = call ptr @create_object()
  %outer_pool = call ptr @llvm.objc.autoreleasePoolPush()

  ; First inner pool
  %inner1_pool = call ptr @llvm.objc.autoreleasePoolPush()
  call ptr @llvm.objc.autorelease(ptr %obj1)
  call void @llvm.objc.autoreleasePoolPop(ptr %inner1_pool)

  ; Second inner pool with nested level
  %inner2_pool = call ptr @llvm.objc.autoreleasePoolPush()
  %inner3_pool = call ptr @llvm.objc.autoreleasePoolPush()
  call ptr @llvm.objc.autorelease(ptr %obj2)
  call void @llvm.objc.autoreleasePoolPop(ptr %inner3_pool)
  call void @llvm.objc.autoreleasePoolPop(ptr %inner2_pool)

  call void @llvm.objc.autoreleasePoolPop(ptr %outer_pool)
  ret void
}

; Autorelease outside inner pool prevents optimization
define void @test_autorelease_outside_inner_pool() {
; CHECK-LABEL: define void @test_autorelease_outside_inner_pool() {
; CHECK-NEXT:    [[OBJ1:%.*]] = call ptr @create_object()
; CHECK-NEXT:    [[OBJ2:%.*]] = call ptr @create_object()
; CHECK-NEXT:    call void @llvm.objc.release(ptr [[OBJ1]]) #[[ATTR0]], !clang.imprecise_release [[META0]]
; CHECK-NEXT:    call void @llvm.objc.release(ptr [[OBJ2]]) #[[ATTR0]], !clang.imprecise_release [[META0]]
; CHECK-NEXT:    ret void
;
  %obj1 = call ptr @create_object()
  %obj2 = call ptr @create_object()
  %outer_pool = call ptr @llvm.objc.autoreleasePoolPush()

  ; This autorelease is NOT in an inner pool, so outer pool can't be optimized
  call ptr @llvm.objc.autorelease(ptr %obj1)

  ; Inner pool with autorelease (shadowed)
  %inner_pool = call ptr @llvm.objc.autoreleasePoolPush()
  call ptr @llvm.objc.autorelease(ptr %obj2)
  call void @llvm.objc.autoreleasePoolPop(ptr %inner_pool)

  call void @llvm.objc.autoreleasePoolPop(ptr %outer_pool)
  ret void
}

; Known ObjC functions don't prevent optimization
define void @test_known_objc_functions() {
; CHECK-LABEL: define void @test_known_objc_functions() {
; CHECK-NEXT:    [[OBJ:%.*]] = call ptr @create_object()
; CHECK-NEXT:    ret void
;
  %obj = call ptr @create_object()
  %pool = call ptr @llvm.objc.autoreleasePoolPush()

  ; These are all known ObjC runtime functions that don't produce autoreleases
  %retained = call ptr @llvm.objc.retain(ptr %obj)
  call void @llvm.objc.release(ptr %obj)

  call void @llvm.objc.autoreleasePoolPop(ptr %pool)
  ret void
}

; Complex shadowing with mixed autoreleases
define void @test_complex_shadowing() {
; CHECK-LABEL: define void @test_complex_shadowing() {
; CHECK-NEXT:    [[OBJ1:%.*]] = call ptr @create_object()
; CHECK-NEXT:    [[OBJ2:%.*]] = call ptr @create_object()
; CHECK-NEXT:    [[OBJ3:%.*]] = call ptr @create_object()
; CHECK-NEXT:    call void @llvm.objc.release(ptr [[OBJ1]]) #[[ATTR0]], !clang.imprecise_release [[META0]]
; CHECK-NEXT:    call void @llvm.objc.release(ptr [[OBJ2]]) #[[ATTR0]], !clang.imprecise_release [[META0]]
; CHECK-NEXT:    [[INNER2_POOL:%.*]] = call ptr @llvm.objc.autoreleasePoolPush() #[[ATTR0]]
; CHECK-NEXT:    [[TMP1:%.*]] = call ptr @llvm.objc.autorelease(ptr [[OBJ3]]) #[[ATTR0]]
; CHECK-NEXT:    call void @llvm.objc.autoreleasePoolPop(ptr [[INNER2_POOL]]) #[[ATTR0]]
; CHECK-NEXT:    ret void
;
  %obj1 = call ptr @create_object()
  %obj2 = call ptr @create_object()
  %obj3 = call ptr @create_object()
  %outer_pool = call ptr @llvm.objc.autoreleasePoolPush()

  ; This autorelease is outside inner pools - prevents optimization
  call ptr @llvm.objc.autorelease(ptr %obj1)

  ; Inner pool 1 with shadowed autorelease
  %inner1_pool = call ptr @llvm.objc.autoreleasePoolPush()
  call ptr @llvm.objc.autorelease(ptr %obj2)
  call void @llvm.objc.autoreleasePoolPop(ptr %inner1_pool)

  ; Some safe ObjC operations
  %retained = call ptr @llvm.objc.retain(ptr %obj3)
  call void @llvm.objc.release(ptr %retained)

  ; Inner pool 2 with shadowed autorelease
  %inner2_pool = call ptr @llvm.objc.autoreleasePoolPush()
  call ptr @llvm.objc.autorelease(ptr %obj3)
  call void @llvm.objc.autoreleasePoolPop(ptr %inner2_pool)

  call void @llvm.objc.autoreleasePoolPop(ptr %outer_pool)
  ret void
}

; Non-ObjC function that may autorelease prevents optimization
define void @test_non_objc_may_autorelease() {
; CHECK-LABEL: define void @test_non_objc_may_autorelease() {
; CHECK-NEXT:    [[POOL:%.*]] = call ptr @llvm.objc.autoreleasePoolPush() #[[ATTR0]]
; CHECK-NEXT:    [[TMP1:%.*]] = call ptr @function_that_might_autorelease()
; CHECK-NEXT:    call void @llvm.objc.autoreleasePoolPop(ptr [[POOL]]) #[[ATTR0]]
; CHECK-NEXT:    ret void
;
  %pool = call ptr @llvm.objc.autoreleasePoolPush()
  call ptr @function_that_might_autorelease()
  call void @llvm.objc.autoreleasePoolPop(ptr %pool)
  ret void
}

; Non-ObjC function that doesn't autorelease allows optimization
define void @test_non_objc_no_autorelease() {
; CHECK-LABEL: define void @test_non_objc_no_autorelease() {
; CHECK-NEXT:    call void @safe_function()
; CHECK-NEXT:    ret void
;
  %pool = call ptr @llvm.objc.autoreleasePoolPush()
  call void @safe_function()
  call void @llvm.objc.autoreleasePoolPop(ptr %pool)
  ret void
}

; Incomplete push/pop pairs across blocks - only inner pairs count
define void @test_incomplete_pairs_inner_shadowing() {
; CHECK-LABEL: define void @test_incomplete_pairs_inner_shadowing() {
; CHECK-NEXT:    [[OBJ:%.*]] = call ptr @create_object()
; CHECK-NEXT:    [[OUTER_POOL:%.*]] = call ptr @llvm.objc.autoreleasePoolPush() #[[ATTR0]]
; CHECK-NEXT:    call void @llvm.objc.release(ptr [[OBJ]]) #[[ATTR0]], !clang.imprecise_release [[META0]]
; CHECK-NEXT:    ret void
;
  %obj = call ptr @create_object()
  %outer_pool = call ptr @llvm.objc.autoreleasePoolPush()

  ; Inner complete pair - autorelease should be shadowed by this
  %inner_pool = call ptr @llvm.objc.autoreleasePoolPush()
  call ptr @llvm.objc.autorelease(ptr %obj)      ; This SHOULD be shadowed by inner pair
  call void @llvm.objc.autoreleasePoolPop(ptr %inner_pool)  ; Completes the inner pair

  ; Note: %outer_pool pop is in a different block (common pattern)
  ; But the autorelease was shadowed by the complete inner pair
  ret void
}

; Helper functions for testing interprocedural analysis

; Safe function that doesn't call autorelease
define void @safe_function() {
  ; Just some computation, no autoreleases
; CHECK-LABEL: define void @safe_function() {
; CHECK-NEXT:    [[X:%.*]] = add i32 1, 2
; CHECK-NEXT:    ret void
;
  %x = add i32 1, 2
  ret void
}

; Function that may produce autoreleases (simulated by calling autorelease)
define ptr @function_that_might_autorelease() {
; CHECK-LABEL: define ptr @function_that_might_autorelease() {
; CHECK-NEXT:    [[OBJ:%.*]] = call ptr @create_object()
; CHECK-NEXT:    [[AUTORELEASED:%.*]] = call ptr @llvm.objc.autorelease(ptr [[OBJ]]) #[[ATTR0]]
; CHECK-NEXT:    ret ptr [[AUTORELEASED]]
;
  %obj = call ptr @create_object()
  %autoreleased = call ptr @llvm.objc.autorelease(ptr %obj)
  ret ptr %autoreleased
}

;.
; CHECK: [[META0]] = !{}
;.
