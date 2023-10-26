# Lenovo V15 G4 AMN DSDT Patches for Linux

This repository contains DSDT (Differentiated System Description Table) patches for the Lenovo V15 G4 AMN notebook to enable keyboard and touchpad functionality on Linux. These patches are essential for ensuring full hardware compatibility with Linux-based operating systems.

## What are DSDT Tables and why do we sometimes need to patch them?
DSDT tables are typically written by the hardware manufacturer and define how the operating system should interact with various hardware components. However, sometimes these tables have issues or inaccuracies, which can lead to hardware compatibility problems or performance issues, especially when running non-Windows operating systems like Linux.

DSDT patches are modifications made to the DSDT table to correct issues, improve hardware support, or optimize the system's ACPI implementation. In this case, the Manufacturers DSDT Table has wrong Interrupt Configurations which need to be patched.

## Usage

Follow these steps to apply the DSDT patches to your Lenovo V15 G4 AMN notebook:

1. Clone this repository to your local machine and change into the project directory:
```shell
git clone git@github.com:hacklian/lenovo_82yu_dsdt_patches.git
cd lenovo_82yu_dsdt_patches
```

2. Run the provided patcher.sh bash script in the project directory:
```shell
./patcher.sh
```

3. Copy the generated DSDT image to the /boot folder:
Note: You need administrative privileges when copying the patched DSDT image to the /boot directory and updating your bootloader configuration.
```shell
sudo cp dist/patched_dsdt.img /boot/patched_dsdt.img
```

4. Update your bootloader configuration to include the patched DSDT image. The specific steps may vary depending on your bootloader. Here's an example for systemd-boot:
	- Open your bootloader configuration file, typically located at `/boot/loader/entries/<your_entry>.conf`.
	- Add the following line to the configuration file:
	```shell
	initrd /patched_dsdt.img
	```
	- Save the configuration file and exit the text editor.
	- Reboot your system.

5. Install the Dynamic Kernel Modules from:
- https://github.com/hacklian/lenovo_82yu_i8042-dkms
- https://github.com/hacklian/lenovo_82yu_i2c_hid-dkms

## Contributing
If you encounter issues or have improvements to the patches, feel free to open an issue or submit a pull request. Your contributions are welcome and appreciated.

## License
This project is licensed under the GNU GENERAL PUBLIC License. See the LICENSE file for details.