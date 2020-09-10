# Data

```@contents
Pages = ["data.md"]
Depth = 6
```

## Source

[GOES-R/S Level 0 data](https://data.nodc.noaa.gov/cgi-bin/iso?id=gov.noaa.ncdc:C01570) is available via NOAA's [Comprehensive Large Array-data Stewardship System](https://www.avl.class.noaa.gov) for all instruments.
The last 14 days are availble for direct download, older data is only available by special order.

The data is stored by instrument on [the CLASS FTP server](ftp://ftp.avl.class.noaa.gov/ddt/NCEI-NC/CS/GOESR-L0/).

The ABI data is bundled by hour into a tar, usually available by the next day.

For example `OR_OPS_ABI-L0_G16_s201912031100124_e201912031200123_c201912040146051.tar`:
- OR: operational system real-time
- ABI-L0: ABI Level 0
- G17: GOES-17 satellite
- s201912031100124: Time and date of the first included CCSDS packet (2019-12-03 11:00:12.4 UTC)
- e201912031200123: Time and date of the last included CCSDS packet (2019-12-03 12:00:12.3 UTC)
- c201912040146051: Time and date the tar archive was created (2019-12-04 01:46:05.1 UTC)

Each archive contains 30 netCDF files each with 2 minutes of packets, meaning one complete ABI timeline (10 minutes in ABI mode 6) is contained in 5 files.

!!! warning
    As the archives are bundled by start time, it's possible that the start of the first timeline and the end of the last timeline are contained in adjacent archives.

The filename convention is specified in Appendix A of the [Product Definition and User's Guide, Volume 2: L0 Products](https://www.goes-r.gov/resources/docs.html#user).

## Format

### ABI

The CCSDS packets are stored as a continouous byte array in the `abi_space_packet_data` variable.

Offsets and sizes to slice the array into individual packets are provided in the `offset_to_packet` and `size_of_packet` variables.

The `number_of_packets` and `number_of_data_bytes` dimensions are useful to check that all the data was read.

!!! warning "Numerical Types"
    The data in the array containing the packets as well as those with the offsets and sizes are typed as signed instead of unsigned integers. For offsets and sizes this does not cause any problems as the size of the array containing the packets is usually smaller than 2 GiB. The data of the packets should be reinterpreted as — or converted to — `UInt8` to avoid problems downstream.

Example of a single netCDF file:
```julia-repl
julia> using NCDatasets
julia> ds = Dataset("OR_ABI-L0-T05_G16_s20193371100124_e20193371102123_c20193371102123.nc")
Dataset: OR_ABI-L0-T05_G16_s20193371100124_e20193371102123_c20193371102123.nc
Group: /

Dimensions
   number_of_packets = 1020569
   number_of_data_bytes = 498844959

Variables
  size_of_packet   (1020569)
    Datatype:    Int32
    Dimensions:  number_of_packets
    Attributes:
     long_name            = size of each packet

  offset_to_packet   (1020569)
    Datatype:    Int32
    Dimensions:  number_of_packets
    Attributes:
     long_name            = index in the abi_space_packet_data variable of the start of the packet

  abi_space_packet_data   (498844959)
    Datatype:    Int8
    Dimensions:  number_of_data_bytes
    Attributes:
     long_name            = GOES-R Advanced Baseline Imager (ABI) L0 CCSDS Space Packets
     coverage_content_type = physicalMeasurement

  percent_uncorrectable_L0_errors
    Attributes:
     units                = percent
     long_name            = percent uncorrectable L0 errors

Global attributes
  dataset_name         = OR_ABI-L0-T05_G16_s20193371100124_e20193371102123_c20193371102123.nc
  naming_authority     = gov.noaa.goes-r
  iso_series_metadata_id = a70be540-c38b-11e0-962b-0800200c9a66
  Conventions          = CF-1.6
  Metadata_Conventions = Unidata Dataset Discovery v1.0, CF-1.6
  standard_name_vocabulary = CF Standard Name Table (v18, 22 July 2011)
  title                = Advanced Baseline Imager (ABI) L0 CCSDS data packets
  summary              = Raw data reconstructed to unprocessed instrument data at full space-time resolution with all available supplemental information to be used in subsequent processing appended.
  keywords             = SPECTRAL/ENGINEERING > INFRARED WAVELENGTHS > SENSOR COUNTS, SPECTRAL/ENGINEERING > VISIBLE WAVELENGTHS > SENSOR COUNTS
  keywords_vocabulary  = NASA Global Change Master Directory (GCMD) Earth Science Keywords, Version 7.0.0.0.0
  license              = Unclassified data.  Access is restricted to approved users only.
  institution          = DOC/NOAA/NESDIS > U.S. Department of Commerce, National Oceanic and Atmospheric Administration, National Environmental Satellite, Data, and Information Services
  date_created         = 2019-12-03T11:02:12Z
  processing_level     = National Aeronautics and Space Administration (NASA) L0
  time_coverage_start  = 2019-12-03T11:00:12Z
  time_coverage_end    = 2019-12-03T11:02:12Z
  timeline_id          = 05
  orbital_slot         = GOES-East
  platform_ID          = G16
  instrument_type      = GOES R Series Advanced Baseline Imager
  instrument_id        = FM1
  production_data_source = Realtime
  production_site      = WCDAS
  production_environment = OE
  id                   = a3af2c4e-74c3-4809-8787-9c049b12b1f8

```

## Packets

The individual packets (loosly) follow the [CCSDS 133.0-B-1 Space Packet Protocol](https://public.ccsds.org/Publications/BlueBooks.aspx) specifications.

### Header

The PUG implies a secondary header of length of 104 bits, but only the `Time Code` fields seem to be shared accross all ABI packets (APIDs). We assume the `User Data` starts after the `Time Code` fields, all other fields are documented in the APID specific formats.

```@raw html
<table>
  <caption>Packet format</caption>
  <thead>
    <tr>
      <th>Part</th>
      <th>Subpart</th>
      <th>Byte</th>
      <th>Bits</th>
      <th>Length</th>
      <th>Field</th>
      <th>Type</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan=10>Primary Header</td>
      <td></td>
      <td rowspan=4>1</td>
      <td>1-3</td>
      <td>3 bits</td>
      <td>Version</td>
      <td>UInt</td>
      <td>Version 1 CCSDS packets are <code>0b000</code></td>
    </tr>
    <tr>
      <td rowspan=4>Identification</td>
      <td>4</td>
      <td>1 bit</td>
      <td>Type</td>
      <td>Bool</td>
      <td>Telemetry is 1, telecommand is 0. This should therefore always be 0.</td>
    </tr>
    <tr>
      <td>5</td>
      <td>1 bit</td>
      <td>Secondary Header flag</td>
      <td>Bool</td>
      <td>Specifies if a secondary header is present. Seemingly always 1.</td>
    </tr>
    <tr>
      <td>6-8</td>
      <td rowspan=2>11 bits</td>
      <td rowspan=2>Application process identifier (APID)</td>
      <td rowspan=2>UInt</td>
      <td rowspan=2>Type of payload included in the packet</td>
    </tr>
    <tr>
      <td>2</td>
      <td>1-8</td>
    </tr>
    <tr>
      <td rowspan=3>Sequence Control</td>
      <td rowspan=2>3</td>
      <td>1-2</td>
      <td>2 bits</td>
      <td>Sequence Flags</td>
      <td>Bool[]</td>
      <td>Always <code>0b11</code></td>
    </tr>
    <tr>
      <td>3-8</td>
      <td rowspan=2>14 bits</td>
      <td rowspan=2>Sequence Count</td>
      <td rowspan=2>UInt</td>
      <td rowspan=2>Packet Sequence Counter module 16384. Each APIDs packets are counted separately.</td>
    </tr>
    <tr>
      <td>4</td>
      <td>1-8</td>
    </tr>
    <tr>
      <td rowspan=2></td>
      <td>5</td>
      <td>1-8</td>
      <td rowspan=2>16 bits</td>
      <td rowspan=2>Data Length</td>
      <td rowspan=2>UInt</td>
      <td rowspan=2>The length of the Data Field of the packet in bytes minus 1 (i.e. length of Data Field = this field + 1). The length only applies to the Data Field, the 6 byte long Primary Header is not included.</td>
    </tr>
    <tr>
      <td>6</td>
      <td>1-8</td>
    </tr>
    <tr>
      <td rowspan=8>Data Field</td>
      <td rowspan=7>Secondary Header</td>
      <td>7</td>
      <td>1-8</td>
      <td rowspan=3>24 bits</td>
      <td rowspan=3>Time Code - Days</td>
      <td rowspan=3>Int</td>
      <td rowspan=3>Encoded as days since 2000-01-01 12:00:00 UTC</td>
    </tr>
    <tr>
      <td>8</td>
      <td>1-8</td>
    </tr>
    <tr>
      <td>9</td>
      <td>1-8</td>
    </tr>
    <tr>
      <td>10</td>
      <td>1-8</td>
      <td rowspan=4>32 bits</td>
      <td rowspan=4>Time Code - Milliseconds</td>
      <td rowspan=4>UInt</td>
      <td rowspan=4>Encoded as milliseconds since the start of the (julian) day (i.e. since 12:00:00 UTC)</td>
    </tr>
    <tr>
      <td>11</td>
      <td>1-8</td>
    </tr>
    <tr>
      <td>12</td>
      <td>1-8</td>
    </tr>
    <tr>
      <td>13</td>
      <td>1-8</td>
    </tr>
    <tr>
      <td>User Data</td>
      <td>14-end</td>
      <td></td>
      <td></td>
      <td>Data</td>
      <td></td>
      <td>This field contains the actual payload and is described below.</td>
    </tr>
  </tbody>
  <tfoot>
    <tr>
      <th>Part</th>
      <th>Subpart</th>
      <th>Byte</th>
      <th>Bits</th>
      <th>Length</th>
      <th>Field</th>
      <th>Type</th>
      <th>Description</th>
    </tr>
  </tfoot>
</table>
```

### ABI User Data

There is no public documentation on the format and layout of the user data available.
The following information has been reverse-engineered from the data itself and various information sources such as papers, specifications for similar data (e.g. the GRB data) and standards.

#### APIDs 480 - 505

- APIDs 480 through 505 contain image data
- Every packet contains 2 vertical rows of samples from one band.
- Four packets form a chunk.
- The rows of samples are spread over the packets such that packet 1's 2 rows are interlaced with 3 rows from packets 2-4.

```
Row:    1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
Packet: 1  2  3  4  1  2  3  4  5  6  7  8  5  6  7  8
Chunk:  1  1  1  1  1  1  1  1  2  2  2  2  2  2  2  2
```

> Every four packets of channel data comprise a data chunk. A data chunk is a collection of eight consecutive detector samples in a single swath from all active columns of a given band. Many detector samples make a swath, and one or more swaths make a scene (Figure 7). Rice compression is done across the rows within the chunk, and then the compressed rows are assembled into packets with every fourth compression block gathered into one packet. ABI uses a 4 × 4 resampling kernel so the loss of a single packet will not result in a hole in imagery but rather slightly degraded radiometric accuracy.[^Kalluri18]

##### APID/Band Information
```@raw html
<table style="width: calc(100vw - 22rem); max-width: calc(100vw - 22rem);">
  <!-- <caption>APID/Band Information</caption> -->
  <thead>
    <tr>
      <th>APID</th>
      <th>Band</th>
      <th>Nominal Wavelength</th>
      <th>Resolution (Nadir GSD)</th>
      <th>East-West ASD</th>
      <th>East-West IFOV</th>
      <th>North-South IFOV</th>
      <th>Bit Depth</th>
      <th>Rows</th>
      <th>Columns</th>
      <th>Size (per Packet)</th>
      <th>Compressed Size (per Packet)</th>
      <th>Packets per Timeline</th>
      <th>FPM</th>
      <th>FPA</th>
      <th>East-West Detector Size</th>
      <th>North-South Detector Size</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>480?</td>
      <td>1</td>
      <td>0.47 μm</td>
      <td>1.0 km</td>
      <td>22 μrad</td>
      <td>22.9 μrad</td>
      <td>22.9 μrad</td>
      <td>11</td>
      <td>676</td>
      <td>3</td>
      <td></td>
      <td></td>
      <td></td>
      <td>VNIR</td>
      <td>A047</td>
      <td>24&nbsp;μm</td>
      <td>24&nbsp;μm</td>
    </tr>
    <tr>
      <td>481</td>
      <td rowspan=5>2</td>
      <td rowspan=5>0.64 μm</td>
      <td rowspan=5>0.5 km</td>
      <td rowspan=5>11&nbsp;μrad</td>
      <td rowspan=5>12.4&nbsp;μrad</td>
      <td rowspan=5>10.5&nbsp;μrad</td>
      <td rowspan=5>12</td>
      <td rowspan=5>5&nbsp;×&nbsp;292</td>
      <td rowspan=5>3</td>
      <td rowspan=5></td>
      <td rowspan=5></td>
      <td rowspan=5></td>
      <td rowspan=5>VNIR</td>
      <td rowspan=5>A064</td>
      <td>13&nbsp;μm</td>
      <td>11&nbsp;μm</td>
    </tr>
    <tr>
      <td>482</td>
    </tr>
    <tr>
      <td>483</td>
    </tr>
    <tr>
      <td>484</td>
    </tr>
    <tr>
      <td>485</td>
    </tr>
    <tr>
      <td>486?</td>
      <td>3</td>
      <td>0.86 μm</td>
      <td>1.0 km</td>
      <td>22 μrad</td>
      <td>22.9 μrad</td>
      <td>22.9 μrad</td>
      <td>11</td>
      <td>676</td>
      <td>3</td>
      <td></td>
      <td></td>
      <td></td>
      <td>VNIR</td>
      <td>A086</td>
      <td>24&nbsp;μm</td>
      <td>24&nbsp;μm</td>
    </tr>
    <tr>
      <td>487?</td>
      <td>4</td>
      <td>1.378 μm</td>
      <td>2.0 km</td>
      <td>44 μrad</td>
      <td>51.5 μrad</td>
      <td>42.0 μrad</td>
      <td>12</td>
      <td>372</td>
      <td>6</td>
      <td></td>
      <td></td>
      <td></td>
      <td>VNIR</td>
      <td>A138</td>
      <td>54&nbsp;μm</td>
      <td>44&nbsp;μm</td>
    </tr>
    <tr>
      <td>488?</td>
      <td>5</td>
      <td>1.61 μm</td>
      <td>1.0 km</td>
      <td>22 μrad</td>
      <td>22.9 μrad</td>
      <td>22.9 μrad</td>
      <td>13</td>
      <td>676</td>
      <td>6</td>
      <td></td>
      <td></td>
      <td></td>
      <td>VNIR</td>
      <td>A161</td>
      <td>24&nbsp;μm</td>
      <td>24&nbsp;μm</td>
    </tr>
    <tr>
      <td>489?</td>
      <td>6</td>
      <td>2.25 μm</td>
      <td>2.0 km</td>
      <td>44 μrad</td>
      <td>51.5 μrad</td>
      <td>42.0 μrad</td>
      <td>11</td>
      <td>372</td>
      <td>6</td>
      <td></td>
      <td></td>
      <td></td>
      <td>VNIR</td>
      <td>A225</td>
      <td>54&nbsp;μm</td>
      <td>44&nbsp;μm</td>
    </tr>
    <tr>
      <td>496?</td>
      <td>7</td>
      <td>3.90 μm</td>
      <td>2.0 km</td>
      <td>44 μrad</td>
      <td>51.5 μrad</td>
      <td>47.7 μrad</td>
      <td>14</td>
      <td>332</td>
      <td>6</td>
      <td></td>
      <td></td>
      <td></td>
      <td>MWIR</td>
      <td>A390</td>
      <td>54&nbsp;μm</td>
      <td>50&nbsp;μm</td>
    </tr>
    <tr>
      <td>497?</td>
      <td>8</td>
      <td>6.185 μm</td>
      <td>2.0 km</td>
      <td>44 μrad</td>
      <td>51.5 μrad</td>
      <td>47.7 μrad</td>
      <td>12</td>
      <td>332</td>
      <td>6</td>
      <td></td>
      <td></td>
      <td></td>
      <td>MWIR</td>
      <td>A618</td>
      <td>54&nbsp;μm</td>
      <td>50&nbsp;μm</td>
    </tr>
    <tr>
      <td>498?</td>
      <td>9</td>
      <td>6.95 μm</td>
      <td>2.0 km</td>
      <td>44 μrad</td>
      <td>51.5 μrad</td>
      <td>47.7 μrad</td>
      <td>13</td>
      <td>332</td>
      <td>6</td>
      <td></td>
      <td></td>
      <td></td>
      <td>MWIR</td>
      <td>A695</td>
      <td>54&nbsp;μm</td>
      <td>50&nbsp;μm</td>
    </tr>
    <tr>
      <td>499?</td>
      <td>10</td>
      <td>7.34 μm</td>
      <td>2.0 km</td>
      <td>44 μrad</td>
      <td>51.5 μrad</td>
      <td>47.7 μrad</td>
      <td>13</td>
      <td>332</td>
      <td>6</td>
      <td></td>
      <td></td>
      <td></td>
      <td>MWIR</td>
      <td>A734</td>
      <td>54&nbsp;μm</td>
      <td>50&nbsp;μm</td>
    </tr>
    <tr>
      <td>500?</td>
      <td>11</td>
      <td>8.50 μm</td>
      <td>2.0 km</td>
      <td>44 μrad</td>
      <td>51.5 μrad</td>
      <td>47.7 μrad</td>
      <td>13</td>
      <td>332</td>
      <td>6</td>
      <td></td>
      <td></td>
      <td></td>
      <td>MWIR</td>
      <td>A850</td>
      <td>54&nbsp;μm</td>
      <td>50&nbsp;μm</td>
    </tr>
    <tr>
      <td>501?</td>
      <td>12</td>
      <td>9.61 μm</td>
      <td>2.0 km</td>
      <td>44 μrad</td>
      <td>51.5 μrad</td>
      <td>47.7 μrad</td>
      <td>13</td>
      <td>332</td>
      <td>6</td>
      <td></td>
      <td></td>
      <td></td>
      <td>LWIR</td>
      <td>A961</td>
      <td>54&nbsp;μm</td>
      <td>50&nbsp;μm</td>
    </tr>
    <tr>
      <td>502?</td>
      <td>13</td>
      <td>10.35 μm</td>
      <td>2.0 km</td>
      <td>44 μrad</td>
      <td>34.3 μrad</td>
      <td>38.1 μrad</td>
      <td>13</td>
      <td>408</td>
      <td>6</td>
      <td></td>
      <td></td>
      <td></td>
      <td>LWIR</td>
      <td>A1035</td>
      <td>36&nbsp;μm</td>
      <td>40&nbsp;μm</td>
    </tr>
    <tr>
      <td>503?</td>
      <td>14</td>
      <td>11.20 μm</td>
      <td>2.0 km</td>
      <td>44 μrad</td>
      <td>34.3 μrad</td>
      <td>38.1 μrad</td>
      <td>13</td>
      <td>408</td>
      <td>6</td>
      <td></td>
      <td></td>
      <td></td>
      <td>LWIR</td>
      <td>A1120</td>
      <td>36&nbsp;μm</td>
      <td>40&nbsp;μm</td>
    </tr>
    <tr>
      <td>504?</td>
      <td>15</td>
      <td>12.30 μm</td>
      <td>2.0 km</td>
      <td>44 μrad</td>
      <td>34.3 μrad</td>
      <td>38.1 μrad</td>
      <td>13</td>
      <td>408</td>
      <td>6</td>
      <td></td>
      <td></td>
      <td></td>
      <td>LWIR</td>
      <td>A1230</td>
      <td>36&nbsp;μm</td>
      <td>40&nbsp;μm</td>
    </tr>
    <tr>
      <td>505?</td>
      <td>16</td>
      <td>13.30 μm</td>
      <td>2.0 km</td>
      <td>44 μrad</td>
      <td>34.3 μrad</td>
      <td>38.1 μrad</td>
      <td>12</td>
      <td>408</td>
      <td>6</td>
      <td></td>
      <td></td>
      <td></td>
      <td>LWIR</td>
      <td>A1330</td>
      <td>36&nbsp;μm</td>
      <td>40&nbsp;μm</td>
    </tr>
  </tbody>
</table>
```

!!! warning "Bit depths"
    There are conflicting numbers on the bit depths of the bands.
    The figures in the table above are from [^Kalluri18] (Table 1) and probably represent the downlinked bit depth.
    > The ABI … samples the radiance … of the Earth in sixteen spectral bands using several arrays of detectors at 14-bit quantization. For Earth scenes, the least significant bits are discarded since they are typically pure noise. This is done to achieve compression efficiency without sacrificing radiometric fidelity to minimize the overall data rate. For each band, the number of bits downlinked (11 to 14) is chosen such that the value of the least significant bit downlinked is less than half the maximum permitted Noise-Equivalent change in Radiance (NEdN) for that band (Table 1). This means that, for a scene of nominal radiance (100% albedo or 300 K), quantization noise is not the dominant contributor to Signal to Noise Ratio (SNR) or Noise-Equivalent delta Temperature (NEdT) (unless the actual SNR or NEdT is significantly better than the requirement).
    [^Schmit17] states
    > The number of bits per pixel (radiometric resolution) is also improved on the ABI (12 for most bands; 14 for the 3.9-μm band)
    and [^Schmit18] repeats
    > There are 12 bits per pixel for all ABI band imagery files except for ABI band 7 (3.9 μm), which has 14 bits per pixel
    The description of the L1b products [^GOESRPUG3] list different bit depths in Table 5.1.3.6.3-1 and states in section 5.1.3.5
    > The bit depth of the Radiances product, 10 to 14 bits, is band dependent, and is based on the bit depth of the downlinked samples from the ABI coupled with optimization considerations for GRB transmission.



##### Image Data Packet Format
```@raw html
<table>
  <!-- <caption>Image Data Packet Format</caption> -->
  <thead>
    <tr>
      <th>Byte</th>
      <th>Bits</th>
      <th>Length</th>
      <th>Field</th>
      <th>Type</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan=2>1</td>
      <td>1-6</td>
      <td>6 bits</td>
      <td>Unknown Field 1a</td>
      <td></td>
      <td>Always 0</td>
    </tr>
    <tr>
      <td>7-8</td>
      <td rowspan=2>10 bits</td>
      <td rowspan=2>Unknown Field 1b</td>
      <td rowspan=2></td>
      <td rowspan=2>Same within a chunk. Same within timeline for APIDs — 480, 486 & 488 — 481–485 — 487, 489, 496–505.</td>
    </tr>

    <tr>
      <td>2</td>
      <td>1-8</td>
    </tr>

    <tr>
      <td rowspan=2>3</td>
      <td>1-6</td>
      <td>6 bits</td>
      <td>Unknown Field 2a</td>
      <td></td>
      <td>Always <code>0b100000</code></td>
    </tr>
    <tr>
      <td>7-8</td>
      <td>2 bits</td>
      <td>Orbital Slot?</td>
      <td></td>
      <td><code>0b01</code> for GOES-16, <code>0b10</code> for GOES-17. Bits 7-8 possibly an orbital slot indicator? (1 = East, 2 = West). At least 2 bits.</td>
    </tr>

    <tr>
      <td rowspan=2>4</td>
      <td>1-3</td>
      <td>3 bits</td>
      <td>Unknown Field 3a</td>
      <td></td>
      <td>Static at <code>0b110</code></td>
    </tr>
    <tr>
      <td>4-8</td>
      <td>5 bits</td>
      <td>APID/Band ID</td>
      <td>UInt</td>
      <td><code>APID = field + 480</code></td>
    </tr>

    <tr>
      <td>5</td>
      <td>1-8</td>
      <td>8 bits</td>
      <td>Scene Type</td>
      <td>UInt8</td>
      <td>Spcifies the scene type.</td>
    </tr>

    <tr>
      <td rowspan=2>6</td>
      <td>1-4</td>
      <td>4 bits</td>
      <td>Packet Number</td>
      <td>UInt</td>
      <td>The nth packet of the chunk. Always 0–3</td>
    </tr>
    <tr>
      <td>5-8</td>
      <td>4 bits</td>
      <td>Obs Flag</td>
      <td>Bool[]</td>
      <td>Bit 7 and/or 8 are 1 during observations depending on the APID</td>
    </tr>

    <tr>
      <td rowspan=2>7</td>
      <td>1-3</td>
      <td>3 bits</td>
      <td>Unknown Field 5a</td>
      <td></td>
      <td>Always <code>0b010</code></td>
    </tr>
    <tr>
      <td>4-8</td>
      <td>5 bits</td>
      <td>Unknown Field 5b</td>
      <td></td>
      <td></td>
    </tr>

    <tr>
      <td>8</td>
      <td>1-8</td>
      <td>8 bits</td>
      <td>Swath #</td>
      <td>UInt8</td>
      <td>Swath number of the scene.</td>
    </tr>

    <tr>
      <td>9</td>
      <td>1-8</td>
      <td>8 bits</td>
      <td>Scene #</td>
      <td>UInt8</td>
      <td>Scene number of the timeline. For full disk is always 0, CONUS is 1 or 2, Meso 1 & 2 are counted together 0-19. Spacelook scenes between observations (slews?) are always 0xff.</td>
    </tr>

    <tr>
      <td rowspan=3>10</td>
      <td>1</td>
      <td>1 bit</td>
      <td>End Marker</td>
      <td>Bool</td>
      <td>Marks the last chunk (4 packets) of a scene</td>
    </tr>
    <tr>
      <td>2</td>
      <td>1 bit</td>
      <td>Start Marker</td>
      <td>Bool</td>
      <td>Marks the first chunk (4 packets) of a scene</td>
    </tr>
    <tr>
      <td>3-8</td>
      <td rowspan=2>14 bits</td>
      <td rowspan=2>Block #</td>
      <td rowspan=2>UInt</td>
      <td rowspan=2>Sequence counter of the scene's chunks</td>
    </tr>

    <tr>
      <td>11</td>
      <td>1-8</td>
    </tr>

    <tr>
      <td>12</td>
      <td>1-8</td>
      <td rowspan=2>16 bits</td>
      <td rowspan=2>Unknown Field 6</td>
      <td rowspan=2>UInt16</td>
      <td rowspan=2>First 5 bits always 0. Changes multiple times during a timeline. Shared among all APIDs.</td>
    </tr>

    <tr>
      <td>13</td>
      <td>1-8</td>
    </tr>

    <tr>
      <td>14</td>
      <td>1-8</td>
      <td rowspan=2>11 bits</td>
      <td rowspan=2>Unknown Field 7a</td>
      <td rowspan=2>UInt</td>
      <td rowspan=2>Except for short interruptions (calibration scenes?) always <code>0b00000110100</code></td>
    </tr>

    <tr>
      <td rowspan=2>15</td>
      <td>1-3</td>
    </tr>
    <tr>
      <td>4-8</td>
      <td>5 bits</td>
      <td>Satellite Id?</td>
      <td>UInt</td>
      <td>Bits 4-8 are always <code>0b00001</code> on GOES-16 and <code>0b10001</code> on GOES-17. Possibly reversed satellite number <code>0b00001 => 0b10000 = 16, 0b10001 => 0b10001 = 17</code></td>
    </tr>

    <tr>
      <td>16</td>
      <td>1-8</td>
      <td rowspan=4>32 bits</td>
      <td rowspan=4>N/S offset from SSB</td>
      <td rowspan=4>Float32</td>
      <td rowspan=4>North to south offset from satellite sub-point for image center in radians.</td>
    </tr>
    <tr>
      <td>17</td>
      <td>1-8</td>
    </tr>
    <tr>
      <td>18</td>
      <td>1-8</td>
    </tr>
    <tr>
      <td>19</td>
      <td>1-8</td>
    </tr>

    <tr>
      <td>20</td>
      <td>1-8</td>
      <td rowspan=4>32 bits</td>
      <td rowspan=4>E/W offset from SSB</td>
      <td rowspan=4>Float32</td>
      <td rowspan=4>East to west offset from satellite sub-point for image center in radians.</td>
    </tr>
    <tr>
      <td>21</td>
      <td>1-8</td>
    </tr>
    <tr>
      <td>22</td>
      <td>1-8</td>
    </tr>
    <tr>
      <td>23</td>
      <td>1-8</td>
    </tr>
  </tbody>
  <tfoot>
    <tr>
      <th>Byte</th>
      <th>Bits</th>
      <th>Length</th>
      <th>Field</th>
      <th>Type</th>
      <th>Description</th>
    </tr>
  </tfoot>
</table>
```

What's missing?
- Timeline ID / ABI Mode (available from the netCDF metadata & filename)
- Active detector columns
- Active electronics side
- Compression configuration

##### Scene Types
```@raw html
<table>
  <caption>Scene Types</caption>
  <thead>
    <tr>
      <th colspan=2>Value</th>
      <th rowspan=2>Description</th>
      <th rowspan=2>East-West Extend</th>
      <th rowspan=2>North-South Extend</th>
      <th rowspan=2>#&nbsp;Swaths</th>
    </tr>
    <tr>
      <th>Hex</th>
      <th>Dec</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>0x00</td>
      <td>0</td>
      <td>Full Disk</td>
      <td>17.4°</td>
      <td>17.4°</td>
      <td>22</td>
    </tr>
    <tr>
      <td>0x01</td>
      <td>1</td>
      <td>CONUS</td>
      <td>5000&nbsp;km</td>
      <td>3000&nbsp;km</td>
      <td>6</td>
    </tr>
    <tr>
      <td>0x02</td>
      <td>2</td>
      <td>MESO 1</td>
      <td>1000&nbsp;km</td>
      <td>1000&nbsp;km</td>
      <td>2</td>
    </tr>
    <tr>
      <td>0x03</td>
      <td>3</td>
      <td>MESO 2</td>
      <td>1000&nbsp;km</td>
      <td>1000&nbsp;km</td>
      <td>2</td>
    </tr>
    <tr>
      <td>0x05</td>
      <td>5</td>
      <td>VIS StarLook</td>
      <td></td>
      <td></td>
      <td></td>
    </tr>
    <tr>
      <td>0x0a</td>
      <td>10</td>
      <td>IR StarLook</td>
      <td></td>
      <td></td>
      <td></td>
    </tr>
    <tr>
      <td>0x0b</td>
      <td>11</td>
      <td>IR Calibration <br/> (possibly blackbody/ICT calibration?)</td>
      <td></td>
      <td></td>
      <td></td>
    </tr>
    <tr>
      <td>0x0d</td>
      <td>13</td>
      <td>SpaceLook</td>
      <td></td>
      <td></td>
      <td></td>
    </tr>
    <tr>
      <td>?</td>
      <td>?</td>
      <td>ScanOps</td>
      <td></td>
      <td></td>
      <td></td>
    </tr>
    <tr>
      <td>?</td>
      <td>?</td>
      <td>NadirStare</td>
      <td></td>
      <td></td>
      <td></td>
    </tr>
  </tbody>
</table>
```

##### Data Compression

> ABI compresses the samples from a single detector element into a compression block via the onboard lossless Rice compression algorithm during the creation of the CCSDS packets.[^GOESRDataBook]

## Documents

[^Kalluri18]:

    Kalluri, Satya, Christian Alcala, James Carr, Paul Griffith, William Lebair, Dan Lindsey, Randall Race, Xiangqian Wu, and Spencer Zierk

    “From Photons to Pixels: Processing Data from the Advanced Baseline Imager”

    Remote Sensing 10, no. 2 (January 26, 2018): 177.

    [doi:10.3390/rs10020177](https://doi.org/10.3390/rs10020177)

[^GOESRDataBook]:

    National Aeronautics and Space Administration: GOES-R Series Program Office

    “GOES-R Series Data Book”

    Revision A (May 2019) CDRL PM-14

[^GOESRPUG3]:

    National Aeronautics and Space Administration: GOES-R Series Program Office

    “GOES R Series Product Definition and Users’ Guide - Volume 3: L1b Products”

    Revision G.2 (March 8, 2019)

[^Schmit17]:

    Schmit, Timothy J., Paul Griffith, Mathew M. Gunshor, Jaime M. Daniels, Steven J. Goodman, and William J. Lebair

    “A Closer Look at the ABI on the GOES-R Series”

    Bulletin of the American Meteorological Society 98, no. 4 (April 2017): 681–98.

    [doi:10.1175/BAMS-D-15-00230.1](https://doi.org/10.1175/BAMS-D-15-00230.1)

[^Schmit18]:

    Schmit, Timothy J., Scott S. Lindstrom, Jordan J. Gerth, and Mathew M. Gunshor

    “Applications of the 16 Spectral Bands on the Advanced Baseline Imager (ABI)”

    Journal of Operational Meteorology 06, no. 04 (June 8, 2018): 33–46.

    [doi:10.15191/nwajom.2018.0604](https://doi.org/10.15191/nwajom.2018.0604)
