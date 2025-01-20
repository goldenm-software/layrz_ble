@file:Suppress("SpellCheckingInspection")

package com.layrz.layrz_ble

import java.util.UUID

fun standarizeUuid(uuid: UUID): String {
    return uuid.toString().uppercase()
}