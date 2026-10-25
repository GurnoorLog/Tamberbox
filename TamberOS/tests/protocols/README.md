The virtual-pointer XML is vendored from
https://github.com/swaywm/wlr-protocols/blob/master/unstable/wlr-virtual-pointer-unstable-v1.xml
(retrieved 2026-10-25). Its copyright and permissive license are retained inside
the XML. The repository copy, rather than a live download, is compiled by the
test build. `tests/virtual_pointer.c` is original test code. No physical input
access is used. The helper's 1280x720 coordinate extent matches the isolated CI
output; it is not a general-purpose automation daemon.
