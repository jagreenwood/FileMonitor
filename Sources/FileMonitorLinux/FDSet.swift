// https://github.com/kylef-archive/fd/blob/master/Sources/FDSet.swift

import Foundation
#if canImport(CInotify)
import CInotify
#endif

func fdSet(_ descriptor: Int32, _ set: inout fd_set) {
    let intOffset = Int(descriptor / 16)
    let bitOffset = Int(descriptor % 16)
    let mask = 1 << bitOffset

    switch intOffset {
        case 0: set.__fds_bits.0 = set.__fds_bits.0 | mask
        case 1: set.__fds_bits.1 = set.__fds_bits.1 | mask
        case 2: set.__fds_bits.2 = set.__fds_bits.2 | mask
        case 3: set.__fds_bits.3 = set.__fds_bits.3 | mask
        case 4: set.__fds_bits.4 = set.__fds_bits.4 | mask
        case 5: set.__fds_bits.5 = set.__fds_bits.5 | mask
        case 6: set.__fds_bits.6 = set.__fds_bits.6 | mask
        case 7: set.__fds_bits.7 = set.__fds_bits.7 | mask
        case 8: set.__fds_bits.8 = set.__fds_bits.8 | mask
        case 9: set.__fds_bits.9 = set.__fds_bits.9 | mask
        case 10: set.__fds_bits.10 = set.__fds_bits.10 | mask
        case 11: set.__fds_bits.11 = set.__fds_bits.11 | mask
        case 12: set.__fds_bits.12 = set.__fds_bits.12 | mask
        case 13: set.__fds_bits.13 = set.__fds_bits.13 | mask
        case 14: set.__fds_bits.14 = set.__fds_bits.14 | mask
        case 15: set.__fds_bits.15 = set.__fds_bits.15 | mask
        default: break
    }
}

func fdZero(_ set: inout fd_set) {
    set.__fds_bits = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}
