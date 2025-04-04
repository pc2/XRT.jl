#include "experimental/xrt_ip.h"
#include "experimental/xrt_system.h"
#include "experimental/xrt_xclbin.h"
#include "experimental/xrt_ini.h"
#include "experimental/xrt_xclbin.h"
#include "experimental/xrt_message.h"
#include "jlcxx/jlcxx.hpp"
#include "jlcxx/stl.hpp"
#include "version.h"
#include "xrt/xrt_bo.h"
#include "xrt/xrt_device.h"
#include "xrt/xrt_kernel.h"

enum class not_implemented : uint8_t { not_implemented = 0 };

JLCXX_MODULE define_module_xrtwrap(jlcxx::Module& mod) {
    if (XRT_MAJOR(XRT_VERSION_CODE) < 2 || XRT_MINOR(XRT_VERSION_CODE) < 14) {
        throw std::runtime_error(
            std::string(
                "Minimum supported XRT version is 2.14. Found version: ") +
            xrt_build_version);
    }
    mod.set_const("XRT_VERSION_MAJOR", XRT_MAJOR(XRT_VERSION_CODE));
    mod.set_const("XRT_VERSION_MINOR", XRT_MINOR(XRT_VERSION_CODE));
    mod.add_type<xrt::autostart>("Autostart");

    // UUID
    mod.add_type<xrt::uuid>("UUID")
        .method("string", &xrt::uuid::to_string);

    // Device
    mod.add_type<xrt::device>("Device")
        .constructor<unsigned int>()
        .constructor<std::string&>()
        .method("load_xclbin!",
                static_cast<xrt::uuid (xrt::device::*)(const std::string&)>(
                    &xrt::device::load_xclbin))
        //.method("load_xclbin", static_cast<xrt::uuid (xrt::device::*)(const
        // xrt::xclbin&)>(&xrt::device::load_xclbin))
        .method("get_xclbin_uuid", &xrt::device::get_xclbin_uuid)
        .method("get_info_bdf", [](xrt::device& d) { return d.get_info<xrt::info::device::bdf>(); })
        .method("get_info_interface_uuid", [](xrt::device& d) { return d.get_info<xrt::info::device::interface_uuid>(); })
        .method("get_info_kdma", [](xrt::device& d) { return d.get_info<xrt::info::device::kdma>(); })
        .method("get_info_max_clock_frequency_mhz", [](xrt::device& d) { return d.get_info<xrt::info::device::max_clock_frequency_mhz>(); })
        .method("get_info_m2m", [](xrt::device& d) { return d.get_info<xrt::info::device::m2m>(); })
        .method("get_info_name", [](xrt::device& d) { return d.get_info<xrt::info::device::name>(); })
        .method("get_info_nodma", [](xrt::device& d) { return d.get_info<xrt::info::device::nodma>(); })
        .method("get_info_offline", [](xrt::device& d) { return d.get_info<xrt::info::device::offline>(); })
        .method("get_info_electrical", [](xrt::device& d) { return d.get_info<xrt::info::device::electrical>(); })
        .method("get_info_thermal", [](xrt::device& d) { return d.get_info<xrt::info::device::thermal>(); })
        .method("get_info_mechanical", [](xrt::device& d) { return d.get_info<xrt::info::device::mechanical>(); })
        .method("get_info_memory", [](xrt::device& d) { return d.get_info<xrt::info::device::memory>(); })
        .method("get_info_platform", [](xrt::device& d) { return d.get_info<xrt::info::device::platform>(); })
        .method("get_info_pcie_info", [](xrt::device& d) { return d.get_info<xrt::info::device::pcie_info>(); })
        .method("get_info_host", [](xrt::device& d) { return d.get_info<xrt::info::device::host>(); })
        .method("get_info_aie", [](xrt::device& d) { return d.get_info<xrt::info::device::aie>(); })
        .method("get_info_aie_shim", [](xrt::device& d) { return d.get_info<xrt::info::device::aie_shim>(); })
        .method("get_info_dynamic_regions", [](xrt::device& d) { return d.get_info<xrt::info::device::dynamic_regions>(); })
        .method("get_info_vmr", [](xrt::device& d) { return d.get_info<xrt::info::device::vmr>(); });

    // Buffer object
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
        .method("read!", static_cast<void (xrt::bo::*)(void*, size_t, size_t)>(
                             &xrt::bo::read))
        .method("read!", static_cast<void (xrt::bo::*)(void*)>(&xrt::bo::read))
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

    // XCLBIN
    mod.add_type<xrt::xclbin::mem>("XclbinMem")
        .method("get_tag", &xrt::xclbin::mem::get_tag)
        .method("get_base_address", &xrt::xclbin::mem::get_base_address)
        .method("get_size_kb", &xrt::xclbin::mem::get_size_kb)
        .method("get_used", &xrt::xclbin::mem::get_used)
        .method("get_type", &xrt::xclbin::mem::get_type)
        .method("get_index", &xrt::xclbin::mem::get_index);
    mod.add_type<xrt::xclbin::arg>("XclbinArg")
        .method("get_name", &xrt::xclbin::arg::get_name)
        .method("get_mems", &xrt::xclbin::arg::get_mems)
        .method("get_port", &xrt::xclbin::arg::get_port)
        .method("get_size", &xrt::xclbin::arg::get_size)
        .method("get_offset", &xrt::xclbin::arg::get_offset)
        .method("get_host_type", &xrt::xclbin::arg::get_host_type)
        .method("get_index", &xrt::xclbin::arg::get_index);
    mod.add_type<xrt::xclbin::ip>("XclbinIP")
        .method("get_name", &xrt::xclbin::ip::get_name)
        .method("get_type", &xrt::xclbin::ip::get_type)
        .method("get_control_type", &xrt::xclbin::ip::get_control_type)
        .method("get_num_args", &xrt::xclbin::ip::get_num_args)
        .method("get_args", &xrt::xclbin::ip::get_args)
        .method("get_arg", &xrt::xclbin::ip::get_arg)
        .method("get_base_address", &xrt::xclbin::ip::get_base_address)
        .method("get_size", &xrt::xclbin::ip::get_size);
    auto xclbinkernel = mod.add_type<xrt::xclbin::kernel>("XclbinKernel")
        .method("get_name", &xrt::xclbin::kernel::get_name)
        .method("get_cus", [](xrt::xclbin::kernel& k) { return k.get_cus(); })
        .method("get_cus", [](xrt::xclbin::kernel& k, const std::string& name) { return k.get_cus(name); })
        .method("get_cu", &xrt::xclbin::kernel::get_cu)
        .method("get_num_args", &xrt::xclbin::kernel::get_num_args)
        .method("get_args", [](xrt::xclbin::kernel& k) { return k.get_args(); })
        .method("get_arg", &xrt::xclbin::kernel::get_arg);
    #if XRT_MAJOR(XRT_VERSION_CODE) >= 2 && XRT_MINOR(XRT_VERSION_CODE) >= 16
        xclbinkernel.method("get_type", &xrt::xclbin::kernel::get_type);
    #else
        xclbinkernel.method("get_type", [](xrt::xclbin::kernel& k) -> void {});
    #endif

    auto xclbin = mod.add_type<xrt::xclbin>("Xclbin")
        .constructor<const std::string&>()
        .method("get_kernels", &xrt::xclbin::get_kernels)
        .method("get_kernel", &xrt::xclbin::get_kernel)
        .method("get_ips", [](xrt::xclbin& x) { return x.get_ips(); })
        .method("get_ips", [](xrt::xclbin& x, const std::string& name) { return x.get_ips(name); })
        .method("get_ip", &xrt::xclbin::get_ip)
        .method("get_mems", &xrt::xclbin::get_mems)
        .method("get_xsa_name", &xrt::xclbin::get_xsa_name)
        .method("get_fpga_device_name", &xrt::xclbin::get_fpga_device_name)
        .method("get_uuid", &xrt::xclbin::get_uuid)
        .method("get_target_type", &xrt::xclbin::get_target_type);
    #if XRT_MAJOR(XRT_VERSION_CODE) >= 2 && XRT_MINOR(XRT_VERSION_CODE) >= 16
        xclbin.method("get_interface_uuid", &xrt::xclbin::get_interface_uuid);
    #else
        xclbin.method("get_interface_uuid", [](xrt::xclbin& x) -> void {});
    #endif

    // Kernel
    mod.add_type<xrt::kernel>("Kernel")
        .constructor<const xrt::device&, const xrt::uuid&, const std::string&,
                     xrt::kernel::cu_access_mode>()
        .method("group_id", &xrt::kernel::group_id)
        .method("offset", &xrt::kernel::offset)
        .method("get_name", &xrt::kernel::get_name)
        .method("get_xclbin", &xrt::kernel::get_xclbin);

    // Run
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

    // Configuration
    mod.method("set!", static_cast<void (*)(const std::string&, const std::string&)>(
        &xrt::ini::set));
    mod.method("set!", static_cast<void (*)(const std::string&, unsigned int)>(
        &xrt::ini::set));

    // Message
    mod.method("log", &xrt::message::log);
}

// ----------------------------------- Enums -----------------------------------

JLCXX_MODULE define_module_target_type(jlcxx::Module& mod) {
    // Target type enum
    mod.add_bits<xrt::xclbin::target_type>("Type", jlcxx::julia_type("CppEnum"));
    mod.set_const("hw", xrt::xclbin::target_type::hw);
    mod.set_const("sw_emu", xrt::xclbin::target_type::sw_emu);
    mod.set_const("hw_emu", xrt::xclbin::target_type::hw_emu);
}

JLCXX_MODULE define_module_memory_type(jlcxx::Module& mod) {
    // Memory type enum
    mod.add_bits<xrt::xclbin::mem::memory_type>("Type", jlcxx::julia_type("CppEnum"));
    mod.set_const("ddr3", xrt::xclbin::mem::memory_type::ddr3);
    mod.set_const("ddr4", xrt::xclbin::mem::memory_type::ddr4);
    mod.set_const("dram", xrt::xclbin::mem::memory_type::dram);
    mod.set_const("streaming", xrt::xclbin::mem::memory_type::streaming);
    mod.set_const("preallocated_global", xrt::xclbin::mem::memory_type::preallocated_global);
    mod.set_const("are", xrt::xclbin::mem::memory_type::are);
    mod.set_const("hbm", xrt::xclbin::mem::memory_type::hbm);
    mod.set_const("bram", xrt::xclbin::mem::memory_type::bram);
    mod.set_const("uram", xrt::xclbin::mem::memory_type::uram);
    mod.set_const("streaming_connection", xrt::xclbin::mem::memory_type::streaming_connection);
    mod.set_const("host", xrt::xclbin::mem::memory_type::host);
}

JLCXX_MODULE define_module_kernel_type(jlcxx::Module& mod) {
    #if XRT_MAJOR(XRT_VERSION_CODE) >= 2 && XRT_MINOR(XRT_VERSION_CODE) >= 16
        mod.add_bits<xrt::xclbin::kernel::kernel_type>("Type", jlcxx::julia_type("CppEnum"));
        mod.set_const("none", xrt::xclbin::kernel::kernel_type::none);
        mod.set_const("pl", xrt::xclbin::kernel::kernel_type::pl);
        mod.set_const("ps", xrt::xclbin::kernel::kernel_type::ps);
        mod.set_const("dpu", xrt::xclbin::kernel::kernel_type::dpu);
    #else
        mod.add_bits<not_implemented>("Type", jlcxx::julia_type("CppEnum"));
        mod.set_const("NOT_IMPLEMENTED", not_implemented::not_implemented);
    #endif
}

JLCXX_MODULE define_module_control_type(jlcxx::Module& mod) {
    // Control type enum
    mod.add_bits<xrt::xclbin::ip::control_type>("Type", jlcxx::julia_type("CppEnum"));
    mod.set_const("hs", xrt::xclbin::ip::control_type::hs);
    mod.set_const("chain", xrt::xclbin::ip::control_type::chain);
    mod.set_const("none", xrt::xclbin::ip::control_type::none);
    mod.set_const("fa", xrt::xclbin::ip::control_type::fa);
}

JLCXX_MODULE define_module_ip_type(jlcxx::Module& mod) {
    // IP type enum
    mod.add_bits<xrt::xclbin::ip::ip_type>("Type", jlcxx::julia_type("CppEnum"));
    mod.set_const("pl", xrt::xclbin::ip::ip_type::pl);
    mod.set_const("ps", xrt::xclbin::ip::ip_type::ps);
}

JLCXX_MODULE define_module_device_info_params(jlcxx::Module& mod) {
    // Device enum
    mod.add_bits<xrt::info::device>("Type", jlcxx::julia_type("CppEnum"));
    mod.set_const("bdf", xrt::info::device::bdf);
    mod.set_const("interface_uuid", xrt::info::device::interface_uuid);
    mod.set_const("kdma", xrt::info::device::kdma);
    mod.set_const("max_clock_frequency_mhz", xrt::info::device::max_clock_frequency_mhz);
    mod.set_const("m2m", xrt::info::device::m2m);
    mod.set_const("name", xrt::info::device::name);
    mod.set_const("nodma", xrt::info::device::nodma);
    mod.set_const("offline", xrt::info::device::offline);
    mod.set_const("electrical", xrt::info::device::electrical);
    mod.set_const("thermal", xrt::info::device::thermal);
    mod.set_const("mechanical", xrt::info::device::mechanical);
    mod.set_const("memory", xrt::info::device::memory);
    mod.set_const("platform", xrt::info::device::platform);
    mod.set_const("pcie_info", xrt::info::device::pcie_info);
    mod.set_const("host", xrt::info::device::host);
    mod.set_const("aie", xrt::info::device::aie);
    mod.set_const("aie_shim", xrt::info::device::aie_shim);
    mod.set_const("dynamic_regions", xrt::info::device::dynamic_regions);
    mod.set_const("vmr", xrt::info::device::vmr);
}

JLCXX_MODULE define_module_bo_flags(jlcxx::Module& mod) {
    // Flags enum
    mod.add_bits<xrt::bo::flags>("Type", jlcxx::julia_type("CppEnum"));
    mod.set_const("NORMAL", xrt::bo::flags::normal);
    mod.set_const("CACHEABLE", xrt::bo::flags::cacheable);
    mod.set_const("DEV_ONLY", xrt::bo::flags::device_only);
    mod.set_const("HOST_ONLY", xrt::bo::flags::host_only);
    mod.set_const("P2P", xrt::bo::flags::p2p);
    mod.set_const("SVM", xrt::bo::flags::svm);
}

JLCXX_MODULE define_module_ert_cmd_state(jlcxx::Module& mod) {
    // ErtCmdState enum
    mod.add_bits<ert_cmd_state>("Type", jlcxx::julia_type("CppEnum"));
    mod.set_const("NEW", ERT_CMD_STATE_NEW);
    mod.set_const("QUEUED", ERT_CMD_STATE_QUEUED);
    mod.set_const("RUNNING", ERT_CMD_STATE_RUNNING);
    mod.set_const("COMPLETED", ERT_CMD_STATE_COMPLETED);
    mod.set_const("ERROR", ERT_CMD_STATE_ERROR);
    mod.set_const("ABORT", ERT_CMD_STATE_ABORT);
    mod.set_const("SUBMITTED", ERT_CMD_STATE_SUBMITTED);
    mod.set_const("TIMEOUT", ERT_CMD_STATE_TIMEOUT);
    mod.set_const("NORESPONSE", ERT_CMD_STATE_NORESPONSE);
    mod.set_const("SKERROR", ERT_CMD_STATE_SKERROR);
    mod.set_const("SKCRASHED", ERT_CMD_STATE_SKCRASHED);
    mod.set_const("MAX", ERT_CMD_STATE_MAX);
}

JLCXX_MODULE define_module_xcl_bo_sync_direction(jlcxx::Module& mod) {
    // Sync direction enum
    mod.add_bits<xclBOSyncDirection>("Type", jlcxx::julia_type("CppEnum"));
    mod.set_const("TO_DEVICE", XCL_BO_SYNC_BO_TO_DEVICE);
    mod.set_const("FROM_DEVICE", XCL_BO_SYNC_BO_FROM_DEVICE);
    mod.set_const("GMIO_TO_AIE", XCL_BO_SYNC_BO_GMIO_TO_AIE);
    mod.set_const("AIE_TO_GMIO", XCL_BO_SYNC_BO_AIE_TO_GMIO);
}

JLCXX_MODULE define_module_cv_status(jlcxx::Module& mod) {
    // CV Status enum
    mod.add_bits<std::cv_status>("Type", jlcxx::julia_type("CppEnum"));
    mod.set_const("NO_TIMEOUT", std::cv_status::no_timeout);
    mod.set_const("TIMEOUT", std::cv_status::timeout);
}


JLCXX_MODULE define_module_cu_access_mode(jlcxx::Module& mod) {
    // CU Access Mode enum
    mod.add_bits<xrt::kernel::cu_access_mode>("Type", jlcxx::julia_type("CppEnum"));
    mod.set_const("EXCLUSIVE", xrt::kernel::cu_access_mode::exclusive);
    mod.set_const("SHARED", xrt::kernel::cu_access_mode::shared);
    mod.set_const("NONE", xrt::kernel::cu_access_mode::none);
}

JLCXX_MODULE define_module_verbosity_level(jlcxx::Module& mod) {
    // Log verbosity level enum
    mod.add_bits<xrt::message::level>("Type", jlcxx::julia_type("CppEnum"));
    mod.set_const("EMERGENCY", xrt::message::level::emergency);
    mod.set_const("ALERT", xrt::message::level::alert);
    mod.set_const("CRITICAL", xrt::message::level::critical);
    mod.set_const("ERROR", xrt::message::level::error);
    mod.set_const("WARNING", xrt::message::level::warning);
    mod.set_const("NOTICE", xrt::message::level::notice);
    mod.set_const("INFO", xrt::message::level::info);
    mod.set_const("DEBUG", xrt::message::level::debug);
}
