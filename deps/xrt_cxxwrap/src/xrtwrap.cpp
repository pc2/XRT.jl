#include "experimental/xrt_ip.h"
#include "experimental/xrt_system.h"
#include "jlcxx/jlcxx.hpp"
#include "version.h"
#include "xrt/xrt_bo.h"
#include "xrt/xrt_device.h"
#include "xrt/xrt_kernel.h"

JLCXX_MODULE define_julia_module(jlcxx::Module& mod) {
    if (XRT_MAJOR(XRT_VERSION_CODE) < 2 || XRT_MINOR(XRT_VERSION_CODE) < 14) {
        throw std::runtime_error(
            std::string(
                "Minimum supported XRT version is 2.14. Found version: ") +
            xrt_build_version);
    }
    mod.set_const("XRT_VERSION_MAJOR", XRT_MAJOR(XRT_VERSION_CODE));
    mod.set_const("XRT_VERSION_MINOR", XRT_MINOR(XRT_VERSION_CODE));
    mod.add_type<xrt::autostart>("Autostart");
    mod.add_type<xrt::uuid>("UUID");
    // Device
    mod.add_type<xrt::device>("Device")
        .constructor<unsigned int>()
        .constructor<std::string&>()
        .method("load_xclbin!",
                static_cast<xrt::uuid (xrt::device::*)(const std::string&)>(
                    &xrt::device::load_xclbin))
        //.method("load_xclbin", static_cast<xrt::uuid (xrt::device::*)(const
        // xrt::xclbin&)>(&xrt::device::load_xclbin))
        .method("get_xclbin_uuid", &xrt::device::get_xclbin_uuid);

    // Sync direction enum
    mod.add_bits<xclBOSyncDirection>("xclBOSyncDirection",
                                     jlcxx::julia_type("CppEnum"));
    mod.set_const("XCL_BO_SYNC_BO_TO_DEVICE", XCL_BO_SYNC_BO_TO_DEVICE);
    mod.set_const("XCL_BO_SYNC_BO_FROM_DEVICE", XCL_BO_SYNC_BO_FROM_DEVICE);
    mod.set_const("XCL_BO_SYNC_BO_GMIO_TO_AIE", XCL_BO_SYNC_BO_GMIO_TO_AIE);
    mod.set_const("XCL_BO_SYNC_BO_AIE_TO_GMIO", XCL_BO_SYNC_BO_AIE_TO_GMIO);

    // Buffer object

    mod.add_bits<xrt::bo::flags>("BOFlags", jlcxx::julia_type("CppEnum"));
    mod.set_const("XRT_BO_FLAGS_NORMAL", xrt::bo::flags::normal);
    mod.set_const("XRT_BO_FLAGS_CACHEABLE", xrt::bo::flags::cacheable);
    mod.set_const("XRT_BO_FLAGS_DEV_ONLY", xrt::bo::flags::device_only);
    mod.set_const("XRT_BO_FLAGS_HOST_ONLY", xrt::bo::flags::host_only);
    mod.set_const("XRT_BO_FLAGS_P2P", xrt::bo::flags::p2p);
    mod.set_const("XRT_BO_FLAGS_SVM", xrt::bo::flags::svm);
    // mod.add_type<xrt::memory_group>("MemoryGroup");
    mod.add_type<xrt::bo::async_handle>("BOAsyncHandle");
    mod.add_type<xrt::bo>("BO")
        .constructor<const xrt::device&, void*, size_t, xrt::bo::flags,
                     xrt::memory_group>()
        .constructor<const xrt::device&, void*, size_t, xrt::memory_group>()
        .constructor<const xrt::device&, size_t, xrt::bo::flags,
                     xrt::memory_group>()
        .constructor<const xrt::device&, size_t, xrt::memory_group>()
        .method("length", &xrt::bo::size)
        .method("address", &xrt::bo::address)
        .method("get_memory_group", &xrt::bo::get_memory_group)
        .method("get_flags", &xrt::bo::get_flags)
        .method("async!",
                static_cast<xrt::bo::async_handle (xrt::bo::*)(
                    xclBOSyncDirection, size_t, size_t)>(&xrt::bo::async))
        .method(
            "async!",
            static_cast<xrt::bo::async_handle (xrt::bo::*)(xclBOSyncDirection)>(
                &xrt::bo::async))
        .method(
            "sync!",
            static_cast<void (xrt::bo::*)(xclBOSyncDirection, size_t, size_t)>(
                &xrt::bo::sync))
        .method("sync!", static_cast<void (xrt::bo::*)(xclBOSyncDirection)>(
                             &xrt::bo::sync))
        .method("map", static_cast<void* (xrt::bo::*)()>(&xrt::bo::map))
        .method("read", static_cast<void (xrt::bo::*)(void*, size_t, size_t)>(
                            &xrt::bo::read))
        .method("read", static_cast<void (xrt::bo::*)(void*)>(&xrt::bo::read))
        .method("write!",
                static_cast<void (xrt::bo::*)(const void*, size_t, size_t)>(
                    &xrt::bo::write))
        .method("write!",
                static_cast<void (xrt::bo::*)(const void*)>(&xrt::bo::write))
        .method("copy",
                static_cast<void (xrt::bo::*)(const xrt::bo&, size_t, size_t,
                                              size_t)>(&xrt::bo::copy))
        .method("copy",
                static_cast<void (xrt::bo::*)(const xrt::bo&)>(&xrt::bo::copy));

    // IP
    mod.add_bits<std::cv_status>("CVStatus", jlcxx::julia_type("CppEnum"));
    mod.set_const("CV_STATUS_NO_TIMEOUT", std::cv_status::no_timeout);
    mod.set_const("CV_STATUS_TIMEOUT", std::cv_status::timeout);
    mod.add_type<xrt::ip::interrupt>("IPInterrupt")
        .method("enable!", &xrt::ip::interrupt::enable)
        .method("disable!", &xrt::ip::interrupt::disable)
        .method("wait", static_cast<void (xrt::ip::interrupt::*)()>(
                            &xrt::ip::interrupt::wait))
        .method("wait", [](xrt::ip::interrupt& i, unsigned int ms) {
            i.wait(std::chrono::milliseconds(ms));
        });
    mod.add_type<xrt::ip>("IP")
        .constructor<const xrt::device&, const xrt::uuid&, const std::string&>()
        .method("write_register!", &xrt::ip::write_register)
        .method("read_register", &xrt::ip::read_register)
        .method("create_interrupt_notify", &xrt::ip::create_interrupt_notify);

    // Kernel
    mod.add_bits<xrt::kernel::cu_access_mode>("CUAccessMode",
                                              jlcxx::julia_type("CppEnum"));
    mod.set_const("XRT_KERNEL_ACCESS_EXCLUSIVE",
                  xrt::kernel::cu_access_mode::exclusive);
    mod.set_const("XRT_KERNEL_ACCESS_SHARED",
                  xrt::kernel::cu_access_mode::shared);
    mod.set_const("XRT_KERNEL_ACCESS_NONE", xrt::kernel::cu_access_mode::none);
    mod.add_type<xrt::kernel>("Kernel")
        .constructor<const xrt::device&, const xrt::uuid&, const std::string&,
                     xrt::kernel::cu_access_mode>()
        .method("group_id", &xrt::kernel::group_id)
        .method("offset", &xrt::kernel::offset)
        .method("get_name", &xrt::kernel::get_name);
    //.method("get_xclbin", &xrt::kernel::get_xclbin);

    // Run
    mod.add_bits<ert_cmd_state>("ErtCmdState", jlcxx::julia_type("CppEnum"));
    mod.set_const("ERT_CMD_STATE_NEW", ERT_CMD_STATE_NEW);
    mod.set_const("ERT_CMD_STATE_QUEUED", ERT_CMD_STATE_QUEUED);
    mod.set_const("ERT_CMD_STATE_RUNNING", ERT_CMD_STATE_RUNNING);
    mod.set_const("ERT_CMD_STATE_COMPLETED", ERT_CMD_STATE_COMPLETED);
    mod.set_const("ERT_CMD_STATE_ERROR", ERT_CMD_STATE_ERROR);
    mod.set_const("ERT_CMD_STATE_ABORT", ERT_CMD_STATE_ABORT);
    mod.set_const("ERT_CMD_STATE_SUBMITTED", ERT_CMD_STATE_SUBMITTED);
    mod.set_const("ERT_CMD_STATE_TIMEOUT", ERT_CMD_STATE_TIMEOUT);
    mod.set_const("ERT_CMD_STATE_NORESPONSE", ERT_CMD_STATE_NORESPONSE);
    mod.set_const("ERT_CMD_STATE_SKERROR", ERT_CMD_STATE_SKERROR);
    mod.set_const("ERT_CMD_STATE_SKCRASHED", ERT_CMD_STATE_SKCRASHED);
    mod.set_const("ERT_CMD_STATE_MAX", ERT_CMD_STATE_MAX);
    mod.add_type<xrt::run>("Run")
        .constructor<const xrt::kernel&>()
        .method("start", static_cast<void (xrt::run::*)()>(&xrt::run::start))
        .method("start", static_cast<void (xrt::run::*)(const xrt::autostart&)>(
                             &xrt::run::start))
        .method("stop", &xrt::run::stop)
        .method("abort", &xrt::run::abort)
        // .method("wait", static_cast<ert_cmd_state (xrt::run::*)(const
        // std::chrono::milliseconds&) const>(&xrt::run::wait))
        .method("wait",
                static_cast<ert_cmd_state (xrt::run::*)(unsigned int) const>(
                    &xrt::run::wait))
        // .method("set_arg!", static_cast<void (xrt::run::*)(int,
        // xrt::bo&)>(&xrt::run::set_arg)) .method("set_arg!", static_cast<void
        // (xrt::run::*)(int,const xrt::bo&)>(&xrt::run::set_arg))
        .method("set_arg!",
                static_cast<void (xrt::run::*)(int, const void*, size_t)>(
                    &xrt::run::set_arg))
        .method("state", &xrt::run::state);

    // System
    mod.method("enumerate_devices", &xrt::system::enumerate_devices);
}
