#!/bin/sh

# Driver location
DRIVER_LOC=/root/hostshared/dma_ip_drivers
TEMP=/root/tmp
FILE1=$TEMP/test.txt
FILE2=$TEMP/test2.txt
FILE3=$TEMP/test_8k.txt
FILE4=$TEMP/test3.txt

# Regression test for the QEMU + xxx + QDMA device.
#
# This requires a little test harness in order to work:
#   * The QDMA needs to be bound to a x86_64 QEMU and a 4K memory must be
#     mapped at 0x102100000 on the "card" interface.  This acts as a dummy SBI
#     with the 4K keyhole.

################################################################################
# TEST1: Load simple data in Direct Interrupt Mode.
################################################################################
echo "TEST1: Load the driver in Direct Interrupt Mode"
insmod $DRIVER_LOC/QDMA/linux-kernel/bin/qdma-pf.ko mode=1:0:2 \
       config_bar=1:0:0 master_pf=1:0
echo "TEST1: Setting the number of queue"
echo 1 > /sys/bus/pci/devices/0000:02:00.0/qdma/qmax
echo "TEST1: Configuring H2C and C2H mm queues"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl qdma02000 q add idx 0 mode mm dir h2c
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl qdma02000 q add idx 0 mode mm dir c2h
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl qdma02000 q start idx 0 dir c2h
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl qdma02000 q start idx 0 dir h2c
echo "TEST1: Sending 1KB to the device @0x102100000"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-to-device -d /dev/qdma02000-MM-0 -f \
						$FILE1 -s 1024 -a 0x102100000
echo "TEST1: Getting 1KB from the device @0x102100000"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-from-device -d /dev/qdma02000-MM-0 -f \
						$FILE2 -s 1024 -a 0x102100000
echo "TEST1: Unloading the driver"
rmmod qdma-pf.ko
echo "TEST1: Comparing the files"
diff $FILE1 $FILE2 > /dev/null

if [ $? -gt 0 ]
then
    echo "FAILED"
else
    echo "SUCCESS"
fi

echo "TEST1: Cleaning Up"
rm $FILE2

################################################################################
# TEST2: Load simple data in Indirect Interrupt Mode.
################################################################################
echo "TEST2: Load the driver in Indirect Interrupt Mode"
insmod $DRIVER_LOC/QDMA/linux-kernel/bin/qdma-pf.ko mode=1:0:3 \
       config_bar=1:0:0 master_pf=1:0
echo "TEST2: Setting the number of queue"
echo 1 > /sys/bus/pci/devices/0000:02:00.0/qdma/qmax
echo "TEST2: Configuring H2C and C2H mm queues"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl qdma02000 q add idx 0 mode mm dir h2c
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl qdma02000 q add idx 0 mode mm dir c2h
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl qdma02000 q start idx 0 dir c2h
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl qdma02000 q start idx 0 dir h2c
echo "TEST2: Sending 1KB to the device @0x102100000"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-to-device -d /dev/qdma02000-MM-0 -f \
						$FILE1 -s 1024 -a 0x102100000
echo "TEST2: Getting 1KB from the device @0x102100000"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-from-device -d /dev/qdma02000-MM-0 -f \
						$FILE2 -s 1024 -a 0x102100000
echo "TEST2: Unloading the driver"
rmmod qdma-pf.ko
echo "TEST2: Comparing the files"
diff $FILE1 $FILE2 > /dev/null

if [ $? -gt 0 ]
then
    echo "FAILED"
else
    echo "SUCCESS"
fi

echo "TEST2: Cleaning Up"
rm $FILE2

################################################################################
# TEST3: Load data with specific aperture size through a keyhole.
#      * This is a driver specific feature but it exercises running multiple
#        sequential descriptor.  The driver will cut the transfer in two part.
################################################################################
echo "TEST3: Load the driver in Direct Interrupt Mode"
insmod $DRIVER_LOC/QDMA/linux-kernel/bin/qdma-pf.ko mode=1:0:2 \
       config_bar=1:0:0 master_pf=1:0
echo "TEST3: Setting the number of queue"
echo 1 > /sys/bus/pci/devices/0000:02:00.0/qdma/qmax
echo "TEST3: Configuring H2C and C2H mm queues"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl qdma02000 q add idx 0 mode mm dir h2c
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl qdma02000 q add idx 0 mode mm dir c2h
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl qdma02000 q start idx 0 dir c2h
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl qdma02000 q start idx 0 dir h2c \
					  aperture_sz 4096
echo "TEST3: Send 8KB to the device @0x102100000"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-to-device -d /dev/qdma02000-MM-0 -f \
						$FILE3 -s 8192 -a 0x102100000
echo "TEST3: Get last written 4KB from the device @0x102100000"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-from-device -d /dev/qdma02000-MM-0 -f \
						$FILE2 -s 4096 -a 0x102100000
echo "TEST3: Unloading the driver"
rmmod qdma-pf.ko
echo "TEST3: Comparing the files which should be different"
diff $FILE2 $FILE3 > /dev/null

if [ $? -gt 0 ]
then
    echo "SUCCESS"
else
    echo "FAILED"
fi

dd if=$FILE3 of=$FILE4 bs=4k count=1 skip=1 &> /dev/null

echo "TEST3: Comparing the last 4k of the file which should be identical"
diff $FILE4 $FILE2 > /dev/null
if [ $? -gt 0 ]
then
    echo "FAILED"
else
    echo "SUCCESS"
fi

echo "TEST3: Cleaning Up"
rm $FILE2 $FILE4
