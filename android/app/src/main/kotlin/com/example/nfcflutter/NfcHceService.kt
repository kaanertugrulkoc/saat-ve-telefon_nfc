package com.example.nfcflutter

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log

class NfcHceService : HostApduService() {
    
    companion object {
        private const val TAG = "NfcHceService"
        private const val CARD_NUMBER = "3926998730"
        
        // APDU komutları
        private val SELECT_AID_COMMAND = byteArrayOf(0x00.toByte(), 0xA4.toByte(), 0x04.toByte(), 0x00.toByte(), 0x07.toByte(), 0xF0.toByte(), 0x01.toByte(), 0x02.toByte(), 0x03.toByte(), 0x04.toByte(), 0x05.toByte(), 0x06.toByte())
        private val READ_RECORD_COMMAND = byteArrayOf(0x00.toByte(), 0xB2.toByte(), 0x01.toByte(), 0x0C.toByte())
        private val GET_PROCESSING_OPTIONS_COMMAND = byteArrayOf(0x80.toByte(), 0xA8.toByte(), 0x00.toByte(), 0x00.toByte(), 0x02.toByte(), 0x83.toByte(), 0x00.toByte(), 0x00.toByte())
        
        // Başarı yanıtı
        private val SUCCESS_RESPONSE = byteArrayOf(0x90.toByte(), 0x00.toByte())
    }
    
    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        Log.d(TAG, "APDU komutu alındı: ${bytesToHex(commandApdu)}")
        
        return when {
            // SELECT AID komutu
            commandApdu.contentEquals(SELECT_AID_COMMAND) -> {
                Log.d(TAG, "SELECT AID komutu işleniyor")
                handleSelectAid()
            }
            
            // READ RECORD komutu
            commandApdu.contentEquals(READ_RECORD_COMMAND) -> {
                Log.d(TAG, "READ RECORD komutu işleniyor")
                handleReadRecord()
            }
            
            // GET PROCESSING OPTIONS komutu
            commandApdu.contentEquals(GET_PROCESSING_OPTIONS_COMMAND) -> {
                Log.d(TAG, "GET PROCESSING OPTIONS komutu işleniyor")
                handleGetProcessingOptions()
            }
            
            // Diğer komutlar için kart numarasını döndür
            else -> {
                Log.d(TAG, "Bilinmeyen komut, kart numarası döndürülüyor")
                handleUnknownCommand(commandApdu)
            }
        }
    }
    
    private fun handleSelectAid(): ByteArray {
        // FCI Template yanıtı
        val fciTemplate = byteArrayOf(
            0x6F.toByte(), 0x1E.toByte(), // FCI Template
            0x84.toByte(), 0x0E.toByte(), // DF Name
            0x32.toByte(), 0x50.toByte(), 0x41.toByte(), 0x59.toByte(), 0x2E.toByte(), 0x53.toByte(), 0x59.toByte(), 0x53.toByte(), 0x2E.toByte(), 0x44.toByte(), 0x44.toByte(), 0x46.toByte(), 0x30.toByte(), 0x31.toByte(),
            0xA5.toByte(), 0x0C.toByte(), // FCI Proprietary Template
            0x88.toByte(), 0x01.toByte(), 0x01.toByte(), // SFI
            0x5F.toByte(), 0x2D.toByte(), 0x08.toByte(), // Language Preference
            0x74.toByte(), 0x72.toByte(), 0x75.toByte(), 0x73.toByte(), 0x74.toByte(), 0x65.toByte(), 0x64.toByte(), 0x65.toByte(),
            0x9F.toByte(), 0x11.toByte(), 0x01.toByte(), 0x01.toByte() // Issuer Code Table Index
        )
        
        return fciTemplate + SUCCESS_RESPONSE
    }
    
    private fun handleReadRecord(): ByteArray {
        // Kart numarasını Track 2 formatında döndür
        val cardData = CARD_NUMBER.toByteArray()
        val track2Data = byteArrayOf(
            0x70.toByte(), (cardData.size + 2).toByte(), // Record Template
            0x57.toByte(), cardData.size.toByte() // Track 2 Equivalent Data
        ) + cardData
        
        return track2Data + SUCCESS_RESPONSE
    }
    
    private fun handleGetProcessingOptions(): ByteArray {
        // AFL (Application File Locator) yanıtı
        val afl = byteArrayOf(
            0x77.toByte(), 0x0E.toByte(), // Response Message Template Format 2
            0x82.toByte(), 0x02.toByte(), 0x20.toByte(), 0x00.toByte(), // Application Interchange Profile
            0x94.toByte(), 0x0A.toByte(), 0x08.toByte(), 0x01.toByte(), 0x01.toByte(), 0x00.toByte(), 0x10.toByte(), 0x01.toByte(), 0x01.toByte(), 0x00.toByte(), 0x18.toByte(), 0x01.toByte(), 0x02.toByte(), 0x00.toByte() // AFL
        )
        
        return afl + SUCCESS_RESPONSE
    }
    
    private fun handleUnknownCommand(commandApdu: ByteArray): ByteArray {
        // Kart numarasını basit formatta döndür
        val cardData = CARD_NUMBER.toByteArray()
        return cardData + SUCCESS_RESPONSE
    }
    
    override fun onDeactivated(reason: Int) {
        Log.d(TAG, "HCE servisi deaktive edildi, sebep: $reason")
    }
    
    private fun bytesToHex(bytes: ByteArray): String {
        return bytes.joinToString(" ") { "%02X".format(it) }
    }
} 