/*
 * Low-level VFIO-PCI SystemC module/driver.
 *
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Edgar E. Iglesias.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifndef VFIO_H__
#define VFIO_H__
#define __STDC_FORMAT_MACROS

#include <errno.h>
#include <libgen.h>
#include <fcntl.h>
#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/vfs.h>
#include <sys/eventfd.h>

#include <linux/vfio.h>
#include <linux/pci.h>

#include "systemc"

#define MAX_NR_MAPS 32

class vfio_dev
{
public:

	vfio_dev(const char *devname, int iommu_group);
	void mask_irq(uint32_t index, uint32_t start);
	void unmask_irq(uint32_t index, uint32_t start);
	void trigger_irq(uint32_t index, uint32_t start);
	bool reset(void);

	int iommu_map_dma(uint64_t vaddr, uint64_t iova,
			  uint64_t size, uint32_t flags) {
		struct vfio_iommu_type1_dma_map dma_map = { .argsz = sizeof(dma_map) };
		int r;

		dma_map.vaddr = vaddr;
		dma_map.iova = iova;
		dma_map.size = size;
		dma_map.flags = flags;
		r = ioctl(container, VFIO_IOMMU_MAP_DMA, &dma_map);
		if (r < 0) {
			printf("vfio-dma-map: %s\n", strerror(errno));
		}

		return r;
	}

	int iommu_unmap_dma(uint64_t iova, uint64_t size, uint32_t flags) {
		struct vfio_iommu_type1_dma_unmap dma_unmap = { .argsz = sizeof(dma_unmap) };
		int r;

		dma_unmap.iova = iova;
		dma_unmap.size = size;
		dma_unmap.flags = 0;
		r = ioctl(container, VFIO_IOMMU_UNMAP_DMA, &dma_unmap);
		if (r < 0) {
			printf("vfio-dma-unmap: addr=%" PRIx64 " size=%" PRIx64
			       " flags=%x %s\n",
			       iova, size, flags, strerror(errno));
		}

		return r;
	}

	void *map[MAX_NR_MAPS];
	uint64_t map_size[MAX_NR_MAPS];
	int efd_irq;
	int efd_irq_unmask;
private:
	int container;
	int device;

	void print_vfio_iommu_err(void) {
		printf("This failure may be caused by the lack of an IOMMU available\n"
			"to the host Linux kernel.\n"
			"If running on x86 hosts, you may have forgotten to enable one\n"
			"of the following kernel command-line options:\n"
			"intel_iommu=on\n"
			"amd_iommu=on\n\n");

	}

	void print_vfio_device_id_err(void) {
		printf("You may have forgotten to bind the device-id to VFIO\n"
			"for example:\n"
			"echo 10ee 903f > /sys/bus/pci/drivers/vfio-pci/new_id\n"
			"\n\n");
	}
};

void vfio_dev::trigger_irq(uint32_t index, uint32_t start)
{
	struct vfio_irq_set irq_set = {
		.argsz = sizeof(irq_set),
		.flags = VFIO_IRQ_SET_DATA_NONE | VFIO_IRQ_SET_ACTION_TRIGGER,
		.index = index,
		.start = start,
		.count = 1,
	};
	int ret;

	ret = ioctl(device, VFIO_DEVICE_SET_IRQS, &irq_set);
	if (ret < 0) {
		printf("%s index=%d.%d (%m)\n", __func__, index, start);
		perror("vfio-dev");
	}
}

void vfio_dev::mask_irq(uint32_t index, uint32_t start)
{
	struct vfio_irq_set irq_set = {
		.argsz = sizeof(irq_set),
		.flags = VFIO_IRQ_SET_DATA_NONE | VFIO_IRQ_SET_ACTION_MASK,
		.index = index,
		.start = start,
		.count = 1,
	};
	int ret;

	ret = ioctl(device, VFIO_DEVICE_SET_IRQS, &irq_set);
	if (ret < 0) {
		printf("%s index=%d.%d (%m)\n", __func__, index, start);
		perror("vfio-dev");
	}
}

void vfio_dev::unmask_irq(uint32_t index, uint32_t start)
{
	struct vfio_irq_set irq_set = {
		.argsz = sizeof(irq_set),
		.flags = VFIO_IRQ_SET_DATA_NONE | VFIO_IRQ_SET_ACTION_UNMASK,
		.index = index,
		.start = start,
		.count = 1,
	};
	int ret;

	ret = ioctl(device, VFIO_DEVICE_SET_IRQS, &irq_set);
	if (ret < 0) {
		printf("%s index=%d.%d (%m)\n", __func__, index, start);
		perror("vfio-dev");
	}
}

// Returns true on success
bool vfio_dev::reset(void)
{
	int ret;

	ret = ioctl(device, VFIO_DEVICE_RESET);
	return ret == 0;
}

vfio_dev::vfio_dev(const char *devname, int iommu_group)
{
	struct vfio_group_status group_status = {
		.argsz = sizeof(group_status)
	};
	struct vfio_device_info device_info = {
		.argsz = sizeof(device_info)
	};
	struct vfio_irq_info irq_info = {
		.argsz = sizeof(irq_info),
	};
	struct vfio_irq_set *irq_set;
	int32_t *pfd;
	char path[PATH_MAX];
	int group;
	int ret;
	unsigned int i;

	group = -1;
	device = -1;

	container = open("/dev/vfio/vfio", O_RDWR);
	if (container < 0) {
		printf("Failed to open /dev/vfio/vfio, %d (%s)\n",
				container, strerror(errno));
		print_vfio_iommu_err();
		goto error;
	}

	snprintf(path, sizeof(path), "/dev/vfio/%d", iommu_group);
	group = open(path, O_RDWR);
	if (group < 0) {
		printf("Failed to open %s, %d (%s)\n",
				path, group, strerror(errno));
		print_vfio_device_id_err();
		print_vfio_iommu_err();
		goto error;
	}

	ret = ioctl(group, VFIO_GROUP_GET_STATUS, &group_status);
	if (ret) {
		perror("ioctl(VFIO_GROUP_GET_STATUS) failed\n");
		goto error;
	}

	if (!(group_status.flags & VFIO_GROUP_FLAGS_VIABLE)) {
		printf("Group not viable, are all devices attached to vfio?\n");
		goto error;
	}

	ret = ioctl(group, VFIO_GROUP_SET_CONTAINER, &container);
	if (ret) {
		perror("Failed to set group container\n");
		goto error;
	}

	ret = ioctl(container, VFIO_SET_IOMMU, VFIO_TYPE1_IOMMU);
	if (ret) {
		perror("Failed to set IOMMU\n");
		goto error;
	}


	device = ioctl(group, VFIO_GROUP_GET_DEVICE_FD, devname);
	if (device < 0) {
		printf("Failed to get device %s\n", devname);
		perror("vfio-dev");
		goto error;
	}

	if (ioctl(device, VFIO_DEVICE_GET_INFO, &device_info)) {
		perror("vfio-dev: get device info");
		goto error;
	}

	printf("Device supports %d regions, %d irqs\n",
			device_info.num_regions, device_info.num_irqs);

	if (device_info.num_irqs < VFIO_PCI_INTX_IRQ_INDEX + 1) {
		printf("Error, device does not support INTx\n");
	}

	for (i = 0;
	     i < device_info.num_regions && i < (sizeof map / sizeof map[0]);
	     i++) {
		struct vfio_region_info reg = {
			.argsz = sizeof(reg)
		};
		reg.index = i;
		if (ioctl(device, VFIO_DEVICE_GET_REGION_INFO, &reg)) {
			continue;
		}

		map[i] = MAP_FAILED;
		if (i == VFIO_PCI_CONFIG_REGION_INDEX) {
			uint16_t cmd;
			ssize_t r;

			r = pread(device, &cmd, sizeof cmd, reg.offset + PCI_COMMAND);
			if (r < 0) {
				perror("vfio-dev: pread");
				goto error;
			}
			assert(r == sizeof cmd);
			cmd |= PCI_COMMAND_MASTER|PCI_COMMAND_MEMORY;
			r = pwrite(device, &cmd, sizeof cmd, reg.offset + PCI_COMMAND);
			if (r < 0) {
				perror("vfio-dev: pwrite");
				goto error;
			}
			assert(r == sizeof cmd);
		}
		if (reg.flags & VFIO_REGION_INFO_FLAG_MMAP) {
			map[i] = mmap(NULL, (size_t)reg.size,
					PROT_WRITE | PROT_READ, MAP_SHARED, device,
					(off_t)reg.offset);
			map_size[i] = reg.size;
			if (map[i] == MAP_FAILED) {
				perror("vfio-dev: mmap failed\n");
				continue;
			}
			printf("mapped %d at %p\n", i, map[i]);
		}
	}

	// Setup interrupts.
	irq_info.index = VFIO_PCI_INTX_IRQ_INDEX;
	if (ioctl(device, VFIO_DEVICE_GET_IRQ_INFO, &irq_info)) {
		printf("Failed to get IRQ info\n");
		perror("vfio-dev");
		goto error;
	}

	if (irq_info.count != 1 || !(irq_info.flags & VFIO_IRQ_INFO_EVENTFD)) {
		printf("Unexpected IRQ info properties\n");
		goto error;
	}

	irq_set = (struct vfio_irq_set *)malloc(sizeof(*irq_set) + sizeof(*pfd));
	if (!irq_set) {
		printf("Failed to malloc irq_set\n");
		goto error;
	}

	irq_set->argsz = sizeof(*irq_set) + sizeof(*pfd);
	irq_set->index = VFIO_PCI_INTX_IRQ_INDEX;
	irq_set->start = 0;
	pfd = (int32_t *)&irq_set->data;

	efd_irq = eventfd(0, EFD_CLOEXEC);
	if (efd_irq < 0) {
		perror("Failed to get intx eventfd\n");
		goto error;
	}

	efd_irq_unmask = eventfd(0, EFD_CLOEXEC);
	if (efd_irq_unmask < 0) {
		perror("Failed to get unmask eventfd\n");
		goto error;
	}

	*pfd = efd_irq;
	irq_set->flags = VFIO_IRQ_SET_DATA_EVENTFD | VFIO_IRQ_SET_ACTION_TRIGGER;
	irq_set->count = 1;

	if (ioctl(device, VFIO_DEVICE_SET_IRQS, irq_set))
		printf("INTx enable (%m)\n");

	unmask_irq(VFIO_PCI_INTX_IRQ_INDEX, 0);

	reset();
	return;
error:
	if (device >= 0)
		close(device);
	if (group >= 0)
		close(group);
	if (container >= 0)
		close(container);
	device = -1;
	group = -1;
	container = -1;
	SC_REPORT_ERROR("vfio-dev", "Setup failure");
}

#undef basename
#endif
