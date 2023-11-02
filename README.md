# zamee - Wake On Lan (WoL) Tool

zamee is a versatile and user-friendly command-line tool that empowers you to wake up your computer or any other Wake On Lan-enabled device effortlessly. This tool simplifies the process of sending the magic packet to the target device, allowing you to power it on remotely.

![zig](https://img.shields.io/badge/Zig-v0.11-0074C1?logo=zig&logoColor=white&color=%230074C1)
![tests](https://github.com/sectasy0/zamee/actions/workflows/zamee-tests.yml/badge.svg)





## Compilation
```
zig build
```

## Run tests
```shell
zig test src/tests.zig
```

## Usage examples
- Wake up a device with the MAC address `70-85-C2-9D-41-70` using the default port and broadcast address:

```shell
zamee -w 70-85-C2-9D-41-70
```

- Specify a custom port (e.g., port 7) and a custom broadcast address (e.g., 192.168.0.255) to wake up a device with the MAC address `70-85-C2-9D-41-70`:

```shell
zamee -w 70-85-C2-9D-41-70 -p 7 -b 192.168.0.255
```

## CLI options
- `-w, --wake <mac_address>`: Specify the physical address (MAC address) of the device you want to wake up using WoL.
- `-b, --bcast <broadcast_address>`: Set the broadcast address for sending the magic packet (default: 255.255.255.255). Use this option to specify a custom broadcast address if needed.
- `-p, --port <port_number>`: Specify the port to use for Wake On Lan (default: 9). You can specify a different port if your target device uses a non-standard WoL port.
- `-h, --help`: Display this help message and exit. Use this option to view the usage instructions and available options.
- `-v, --version`: Display the tool's version and exit. This option provides information about the current version of `zamee`.

## Error codes

zamee may produce the following error codes to help you diagnose and troubleshoot issues:

- `Error Code 1`: Invalid arguments specified. This error occurs when the command-line arguments are incorrect or missing.
- `Error Code 2`: Invalid physical address format. It indicates that the MAC address provided is not in the correct format.
- `Error Code 3`: Failed to create or send the WoL payload. This error suggests that there was an issue with sending the magic packet. This can be caused by insufficient permissions, often due to the use of port number 9 for Wake-on-LAN.
- `Error Code 4`: Failed to send the WoL payload. This error occurs when the Wake-on-LAN payload was not successfully sent. `(May be caused by insufficient permissions due to use of port number 9)`
- `Error Code 5`: Invalid IPv4 broadcast address format. If the specified broadcast address is not in the expected IPv4 format, this error code will be triggered.
- `Error Code 6`: Stdout failed while printing. This error code is triggered when there is an issue with standard output during the printing process.
- `Error Code 7`: Argument allocator failed. This error suggests that there was a problem with allocating memory for command-line arguments.

## Release history

* 0.0.1
  * release of the first working version.

## Feedback and contributions
Your feedback and contributions are greatly appreciated and can help make this project even better. If you have suggestions, ideas for improvements, or have found any issues, please open an issue on the GitHub repository. Be sure to provide as much detail as possible, including steps to reproduce the issue if applicable.

Thank you for using `zamee`, and we hope it simplifies your remote device management tasks!
