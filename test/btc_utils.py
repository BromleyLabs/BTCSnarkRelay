# Various functions related to Bitcoin header
#
# Author: Bon Filey (bonfiley@gmail.com)
# Copyright 2018 Bromley Labs Inc.

import datetime as dt

DIFFICULTY_ADJUSTMENT_INTERVAL = 2016  # Bitcoin adjusts every 2 weeks
TARGET_TIMESPAN =  14 * 24 * 60 * 60  # 2 weeks
TARGET_TIMESPAN_DIV_4 = TARGET_TIMESPAN / 4
TARGET_TIMESPAN_MUL_4 =  TARGET_TIMESPAN * 4
UNROUNDED_MAX_TARGET =  2**224 - 1 

# @dev swaps endianness 
# @param x 32-bit int 
def swap32(x):
    return int.from_bytes(x.to_bytes(4, byteorder='little'), 
                          byteorder='big', signed=False)

def compact_from_uint256(v):
    """Convert uint256 to compact encoding
    """
    nbytes = (v.bit_length() + 7) >> 3
    compact = 0
    if nbytes <= 3:
        compact = (v & 0xFFFFFF) << 8 * (3 - nbytes)
    else:
        compact = v >> 8 * (nbytes - 3)
        compact = compact & 0xFFFFFF

    # If the sign bit (0x00800000) is set, divide the mantissa by 256 and
    # increase the exponent to get an encoding without it set.
    if compact & 0x00800000:
        compact >>= 8
        nbytes += 1

    return compact | nbytes << 24

def get_time_in_seconds(time_str):
    dtime = dt.datetime.strptime(time_str, '%Y-%m-%d %H:%M:%S')
    epoch =  dt.datetime.strptime('1970-01-01 00:00:00', '%Y-%m-%d %H:%M:%S')
    return int((dtime - epoch).total_seconds())

def target_from_bits(nbits):
    exp = nbits >> 24
    mant = nbits & 0xffffff
    return mant * 256**(exp - 3)

def get_difficulty(nbits):
    target = target_from_bits(nbits)
    difficulty = 0x00000000FFFF0000000000000000000000000000000000000000000000000000 / float(target)
    return difficulty

def compute_nbits(prev_time, start_time, prev_block_number, prev_nbits):
    curr_block_number = prev_block_number + 1 
    adjust_difficulty = (curr_block_number % DIFFICULTY_ADJUSTMENT_INTERVAL) == 0
    if not adjust_difficulty: 
       return prev_nbits  #  
    
    # Adjust difficulty
    actual_timespan = prev_time - start_time
    if actual_timespan < TARGET_TIMESPAN_DIV_4:
        actual_timespan = TARGET_TIMESPAN_DIV_4
    if actual_timespan > TARGET_TIMESPAN_MUL_4:
        actual_timespan = TARGET_TIMESPAN_MUL_4 
   
    prev_target = target_from_bits(prev_nbits) 
    new_target = int(actual_timespan * prev_target / TARGET_TIMESPAN)
    if new_target > UNROUNDED_MAX_TARGET:
        new_target = UNROUNDED_MAX_TARGET

    return compact_from_uint256(new_target)
   
