#!/bin/sh

# Driver location
DRIVER_LOC=/root/hostshared/dma_ip_drivers
TEMP=/root/tmp
FILE1=$TEMP/test.txt
FILE2=$TEMP/test2.txt
FILE3=$TEMP/test_8k.txt
FILE4=$TEMP/test3.txt
FILE5=$TEMP/test4.txt
FILE6=$TEMP/test5.txt

# Use the device connected to the second PCIEHost by default which is the one
# used in the versal-cpie-cpm5 demo.  This might change in case the qdma
# device is wired directly to a remote port.
DEVICE="${DEVICE:-02}"
SYSFS_QMAX=/sys/bus/pci/devices/0000:${DEVICE}:00.0/qdma/qmax
DRVDEV=qdma${DEVICE}000
CHRDEV=/dev/${DRVDEV}-MM-0
DIRMODE=${DEVICE}:0:2
INDIRMODE=${DEVICE}:0:3

# Regression test for the QEMU + xxx + QDMA device.
#
# This requires a little test harness in order to work:
#   * The QDMA needs to be bound to a x86_64 QEMU and a 4K memory must be
#     mapped at 0x102100000 on the "card" interface.  This acts as a dummy SBI
#     with the 4K keyhole.

# Create some dummy files for the tests below.
dd if=/dev/urandom of=$FILE1 bs=1K count=1
dd if=/dev/urandom of=$FILE3 bs=1K count=8

################################################################################
# TEST0: Check that the device is correctly detected by the driver.
################################################################################
echo "TEST0: Load the driver"
insmod $DRIVER_LOC/QDMA/linux-kernel/bin/qdma-pf.ko mode=${DIRMODE}
echo "TEST0: Check that the SYSFS exists."
if [ ! -f ${SYSFS_QMAX} ]; then
    echo "FAILED: cannot continue: check DEVICE variable"
    exit 1
else
    echo "SUCCESS"
fi

echo "TEST0: Unloading the driver"
rmmod qdma-pf.ko

################################################################################
# TEST1: Load simple data in Direct Interrupt Mode.
################################################################################
echo "TEST1: Load the driver in Direct Interrupt Mode"
insmod $DRIVER_LOC/QDMA/linux-kernel/bin/qdma-pf.ko mode=${DIRMODE}
echo "TEST1: Setting the number of queue"
echo 1 > ${SYSFS_QMAX}
echo "TEST1: Configuring H2C and C2H mm queues"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q add idx 0 mode mm dir h2c
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q add idx 0 mode mm dir c2h
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q start idx 0 dir c2h
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q start idx 0 dir h2c
echo "TEST1: Sending 1KB to the device @0x102100000"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-to-device -d ${CHRDEV} -f \
						$FILE1 -s 1024 -a 0x102100000
echo "TEST1: Getting 1KB from the device @0x102100000"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-from-device -d ${CHRDEV} -f \
						$FILE2 -s 1024 -a 0x102100000
echo "TEST1: Unloading the driver"
rmmod qdma-pf.ko
echo "TEST1: Comparing the files"
diff $FILE1 $FILE2 > /dev/null

if [ $? -gt 0 ]
then
    echo "FAILED: file are not identical!"
    exit 1
else
    echo "SUCCESS"
fi

echo "TEST1: Cleaning Up"
rm $FILE2

################################################################################
# TEST2: Load simple data in Indirect Interrupt Mode.
################################################################################
echo "TEST2: Load the driver in Indirect Interrupt Mode"
insmod $DRIVER_LOC/QDMA/linux-kernel/bin/qdma-pf.ko mode=${INDIRMODE}
echo "TEST2: Setting the number of queue"
echo 1 > ${SYSFS_QMAX}
echo "TEST2: Configuring H2C and C2H mm queues"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q add idx 0 mode mm dir h2c
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q add idx 0 mode mm dir c2h
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q start idx 0 dir c2h
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q start idx 0 dir h2c
echo "TEST2: Sending 1KB to the device @0x102100000"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-to-device -d ${CHRDEV} -f \
						$FILE1 -s 1024 -a 0x102100000
echo "TEST2: Getting 1KB from the device @0x102100000"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-from-device -d ${CHRDEV} -f \
						$FILE2 -s 1024 -a 0x102100000
echo "TEST2: Unloading the driver"
rmmod qdma-pf.ko
echo "TEST2: Comparing the files"
diff $FILE1 $FILE2 > /dev/null

if [ $? -gt 0 ]
then
    echo "FAILED: files are not identical!"
    exit 1
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
insmod $DRIVER_LOC/QDMA/linux-kernel/bin/qdma-pf.ko mode=${DIRMODE}
echo "TEST3: Setting the number of queue"
echo 1 > ${SYSFS_QMAX}
echo "TEST3: Configuring H2C and C2H mm queues"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q add idx 0 mode mm dir h2c
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q add idx 0 mode mm dir c2h
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q start idx 0 dir c2h
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q start idx 0 dir h2c \
					  aperture_sz 4096
echo "TEST3: Send 8KB to the device @0x102100000"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-to-device -d ${CHRDEV} -f \
						$FILE3 -s 8192 -a 0x102100000
echo "TEST3: Get last written 4KB from the device @0x102100000"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-from-device -d ${CHRDEV} -f \
						$FILE2 -s 4096 -a 0x102100000
echo "TEST3: Unloading the driver"
rmmod qdma-pf.ko
echo "TEST3: Comparing the files which should be different"
diff $FILE2 $FILE3 > /dev/null

if [ $? -gt 0 ]
then
    echo "SUCCESS"
else
    echo "FAILED: file are identical!"
    exit 1
fi

dd if=$FILE3 of=$FILE4 bs=4k count=1 skip=1

echo "TEST3: Comparing the last 4k of the file which should be identical"
diff $FILE4 $FILE2 > /dev/null
if [ $? -gt 0 ]
then
    echo "FAILED"
    exit 1
else
    echo "SUCCESS"
fi

echo "TEST3: Cleaning Up"
rm $FILE2 $FILE4

################################################################################
# TEST4: Load data and make the descriptor ring overflow.
################################################################################

# The Software producer Index is not reset, if the driver is not unloaded and
# the queue is not stopped.  So just do several dma-ctl in order to overflow
# the descriptor ring, and check the data.

echo "TEST4: Creating two 4K files"
dd if=/dev/urandom of=$FILE5 bs=1K count=4
dd if=/dev/urandom of=$FILE6 bs=1K count=4
echo "TEST4: Load the driver"
insmod $DRIVER_LOC/QDMA/linux-kernel/bin/qdma-pf.ko
echo "TEST4: Setting the number of queue"
echo 1 > /sys/bus/pci/devices/0000:02:00.0/qdma/qmax
echo "TEST4: Configuring H2C / C2H queues, ring size 64"
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q add idx 0 mode mm dir h2c
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q add idx 0 mode mm dir c2h
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q start idx 0 dir h2c \
					  idx_ringsz 1
$DRIVER_LOC/QDMA/linux-kernel/bin/dma-ctl ${DRVDEV} q start idx 0 dir c2h \
					  idx_ringsz 1

echo "TEST4: Sending 128x 4K to the device @0x102100000"
loop=0
while [ "$loop" -lt 64 ]
do
    $DRIVER_LOC/QDMA/linux-kernel/bin/dma-to-device -d ${CHRDEV} -f $FILE5    \
						-s $(( 4 * 1024 ))            \
						-a 0x102100000 > /dev/null
    $DRIVER_LOC/QDMA/linux-kernel/bin/dma-from-device -d ${CHRDEV} -f $FILE2  \
						-s $(( 4 * 1024 ))            \
						-a 0x102100000 > /dev/null
    diff $FILE5 $FILE2 > /dev/null

    if [ $? -gt 0 ]
    then
	echo "FAILED at occurence $loop!"
	exit 1
    fi

    $DRIVER_LOC/QDMA/linux-kernel/bin/dma-to-device -d ${CHRDEV} -f $FILE6    \
						-s $(( 4 * 1024 ))            \
						-a 0x102100000 > /dev/null
    $DRIVER_LOC/QDMA/linux-kernel/bin/dma-from-device -d ${CHRDEV} -f $FILE2  \
						-s $(( 4 * 1024 ))            \
						-a 0x102100000 > /dev/null
    diff $FILE6 $FILE2 > /dev/null

    if [ $? -gt 0 ]
    then
	echo "FAILED at occurence $loop!"
	exit 1
    fi

    echo "SUCCESS $loop / 64"
    loop=`expr $loop + 1`
done

echo "SUCCESS"

echo "TEST4: Unloading the driver"
rmmod qdma-pf.ko

echo "TEST4: Cleaning Up"
rm $FILE2 $FILE5 $FILE6 -f
