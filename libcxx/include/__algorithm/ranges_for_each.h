//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef _LIBCPP___ALGORITHM_RANGES_FOR_EACH_H
#define _LIBCPP___ALGORITHM_RANGES_FOR_EACH_H

#include <__algorithm/for_each.h>
#include <__algorithm/for_each_n.h>
#include <__algorithm/in_fun_result.h>
#include <__concepts/assignable.h>
#include <__config>
#include <__functional/identity.h>
#include <__iterator/concepts.h>
#include <__iterator/projected.h>
#include <__ranges/access.h>
#include <__ranges/concepts.h>
#include <__ranges/dangling.h>
#include <__utility/move.h>

#if !defined(_LIBCPP_HAS_NO_PRAGMA_SYSTEM_HEADER)
#  pragma GCC system_header
#endif

_LIBCPP_PUSH_MACROS
#include <__undef_macros>

#if _LIBCPP_STD_VER >= 20

_LIBCPP_BEGIN_NAMESPACE_STD

namespace ranges {

template <class _Iter, class _Func>
using for_each_result = in_fun_result<_Iter, _Func>;

struct __for_each {
private:
  template <class _Iter, class _Sent, class _Proj, class _Func>
  _LIBCPP_HIDE_FROM_ABI constexpr static for_each_result<_Iter, _Func>
  __for_each_impl(_Iter __first, _Sent __last, _Func& __func, _Proj& __proj) {
    // In the case where we have different iterator and sentinel types, the segmented iterator optimization
    // in std::for_each will not kick in. Therefore, we prefer std::for_each_n in that case (whenever we can
    // obtain the `n`).
    if constexpr (!std::assignable_from<_Iter&, _Sent> && std::sized_sentinel_for<_Sent, _Iter>) {
      auto __n   = __last - __first;
      auto __end = std::__for_each_n(std::move(__first), __n, __func, __proj);
      return {std::move(__end), std::move(__func)};
    } else {
      auto __end = std::__for_each(std::move(__first), std::move(__last), __func, __proj);
      return {std::move(__end), std::move(__func)};
    }
  }

public:
  template <input_iterator _Iter,
            sentinel_for<_Iter> _Sent,
            class _Proj = identity,
            indirectly_unary_invocable<projected<_Iter, _Proj>> _Func>
  _LIBCPP_HIDE_FROM_ABI constexpr for_each_result<_Iter, _Func>
  operator()(_Iter __first, _Sent __last, _Func __func, _Proj __proj = {}) const {
    return __for_each_impl(std::move(__first), std::move(__last), __func, __proj);
  }

  template <input_range _Range,
            class _Proj = identity,
            indirectly_unary_invocable<projected<iterator_t<_Range>, _Proj>> _Func>
  _LIBCPP_HIDE_FROM_ABI constexpr for_each_result<borrowed_iterator_t<_Range>, _Func>
  operator()(_Range&& __range, _Func __func, _Proj __proj = {}) const {
    return __for_each_impl(ranges::begin(__range), ranges::end(__range), __func, __proj);
  }
};

inline namespace __cpo {
inline constexpr auto for_each = __for_each{};
} // namespace __cpo
} // namespace ranges

_LIBCPP_END_NAMESPACE_STD

#endif // _LIBCPP_STD_VER >= 20

_LIBCPP_POP_MACROS

#endif // _LIBCPP___ALGORITHM_RANGES_FOR_EACH_H
