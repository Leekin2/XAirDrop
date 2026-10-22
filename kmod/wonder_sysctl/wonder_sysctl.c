// SPDX-License-Identifier: GPL-2.0
/*
 * /proc/sys/net/wonder/wonder_enable, as created by Xiaomi's own wonder.ko.
 *
 * MIShare shows AirDrop only when this file reads "1" and the DomesticXOsComm
 * service is reachable. The OPAirDrop wonder.ko used on the Xiaomi 15 Ultra has no
 * such sysctl, so this module provides it. It is loaded only after the AirDrop
 * Wi-Fi stack is up and holds no other state.
 */
#include <linux/module.h>
#include <linux/sysctl.h>
#include <net/net_namespace.h>

static int wonder_enable = 1;
static struct ctl_table_header *wonder_sysctl_hdr;

static struct ctl_table wonder_sysctl_table[] = {
	{
		.procname	= "wonder_enable",
		.data		= &wonder_enable,
		.maxlen		= sizeof(int),
		.mode		= 0644,
		.proc_handler	= proc_dointvec_minmax,
		.extra1		= SYSCTL_ZERO,
		.extra2		= SYSCTL_ONE,
	},
	{ }
};

static int __init wonder_sysctl_init(void)
{
	wonder_sysctl_hdr = register_net_sysctl(&init_net, "net/wonder", wonder_sysctl_table);
	if (!wonder_sysctl_hdr) {
		pr_err("[wonder_sysctl] Failed to register sysctl\n");
		return -ENOMEM;
	}
	pr_info("[wonder_sysctl] net.wonder.wonder_enable=%d\n", wonder_enable);
	return 0;
}

static void __exit wonder_sysctl_exit(void)
{
	unregister_net_sysctl_table(wonder_sysctl_hdr);
}

module_init(wonder_sysctl_init);
module_exit(wonder_sysctl_exit);
MODULE_DESCRIPTION("net.wonder.wonder_enable sysctl for MIShare AirDrop");
MODULE_LICENSE("GPL");
