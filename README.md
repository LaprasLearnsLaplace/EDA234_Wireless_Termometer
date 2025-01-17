# Project Overview

This project is part of the **EDA234** course design, aiming to develop a **Multi-functional Thermometer Based on FPGA**. The system can detect and display indoor and outdoor temperatures, with maximum and minimum value recording capabilities. The project is implemented using **VHDL** on a **Nexys A7 FPGA Development Board**.

## Project Features

- **Temperature Detection**
  - Uses **DS18B20 temperature sensor** for outdoor temperature detection
  - Uses **ADT7420** for indoor temperature sensor

- **Temperature Display**
  - Supports **LCD display (DMC 16117A)**, **OLED display**, and **7-segment display**
  - Shows current temperature, maximum and minimum temperature readings

- **Data Recording**
  - Records maximum and minimum temperature values
  - Users can **reset maximum/minimum temperature records** via push buttons

- **Wireless Communication**
  - Implements **Bluetooth module** for wireless transmission of indoor/outdoor temperature data
