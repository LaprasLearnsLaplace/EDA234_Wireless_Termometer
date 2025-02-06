# EDA234 Wireless Temperature Monitoring System

FPGA-based indoor/outdoor temperature monitoring system developed for EDA234 Digital Project Laboratory course at Chalmers University of Technology, implemented on Nexys A7 FPGA development board using VHDL.

### Temperature Sensing
- Indoor: ADT7420 with I2C protocol 
- Outdoor: DS18B20 with 1-Wire protocol 

### Display System
- LCD Display (DMC16117A): Detailed temperature info
- OLED Display: Outdoor unit visualization  
- Seven-segment Display: Time (outdoor) and temperature (indoor)

### Data Management
- DDR2 SDRAM for data storage
- Maximum/minimum temperature tracking
- Real-time clock (DS1302) for temporal logging
- User-configurable temperature thresholds

### Interface & Control
- 4x4 matrix keyboard for settings
- Bluetooth communication (9600 baud)
- Configurable alarm system 
- FPGA onboard buttons/switches

## Hardware Requirements

- Nexys A7-100T FPGA Board
- DMC16117A LCD Module  
- DS1302 RTC Module
- HC-06 Bluetooth Module
- HS96L01W4S03 OLED Display
- 4x4 Matrix Keyboard
- DS18B20 Temperature Sensor
- ADT7420 Temperature Sensor

## Project Structure
-  Indoor unit VHDL implementation
- `outdoor/`: Outdoor unit VHDL implementation
- `Board/`: PCB board files

