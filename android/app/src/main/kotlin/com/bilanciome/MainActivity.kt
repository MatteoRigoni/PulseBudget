package com.bilanciome

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Forza il tema dello splash screen per evitare il pixel verde
        setTheme(R.style.LaunchTheme)
        
        // Mantieni lo schermo acceso durante il caricamento
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        
        // Forza il colore di sfondo a rosso
        window.setBackgroundDrawableResource(android.R.color.darker_gray)
    }
}
