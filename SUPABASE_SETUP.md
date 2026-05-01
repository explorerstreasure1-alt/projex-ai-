# Supabase Yapılandırma Kılavuzu

## Sorun Giderme: Veri Kaydetme Sorunları

### 1. Supabase Storage Bucket Yapılandırması

Ses kayıtlarını kaydetmek için Storage bucket'ı oluşturmanız gerekir:

```sql
-- Storage bucket oluştur (Supabase Dashboard > Storage)
-- Bucket adı: voice-recordings
-- Public: true (isteğe bağlı, dosyalar herkese açık olacaksa)
```

RLS politikaları Storage için:
```sql
-- Storage RLS politikaları
CREATE POLICY "Users can upload own voice recordings"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'voice-recordings' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view own voice recordings"
ON storage.objects FOR SELECT
USING (bucket_id = 'voice-recordings' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own voice recordings"
ON storage.objects FOR DELETE
USING (bucket_id = 'voice-recordings' AND auth.uid()::text = (storage.foldername(name))[1]);
```

### 2. Tablolar ve RLS Politikaları

Supabase Dashboard'da SQL Editor kullanarak `supabase_schema.sql` dosyasını çalıştırın.

### 3. Environment Variables

Vercel Dashboard > Project Settings > Environment Variables:

```
SUPABASE_URL=https://dbwhzmpfgfgemifiuhrp.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
```

**Not:** `window.ENV` objesi için `index.html` içinde bir script ekleyin:

```html
<script>
  window.ENV = {
    SUPABASE_URL: 'https://dbwhzmpfgfgemifiuhrp.supabase.co',
    SUPABASE_ANON_KEY: 'your_anon_key_here'
  };
</script>
```

Veya Vercel'de build time environment variables kullanın.

### 4. Network Kontrolü

Tarayıcı Console'da şu komutları çalıştırarak bağlantıyı test edin:

```javascript
// Supabase bağlantı kontrolü
const { data, error } = await supabaseClient.from('projects').select('count');
console.log('Connection test:', data, error);
```

### 5. Yaygın Hatalar ve Çözümleri

**Hata: "new row violates row-level security policy"**
- Çözüm: RLS politikalarını kontrol edin, user_id alanı auth.uid() ile eşleşmeli

**Hata: "bucket not found"**
- Çözüm: voice-recordings bucket'ı oluşturun

**Hata: "network error"**
- Çözüm: CORS ayarlarını kontrol edin, Vercel domain'inizi Supabase'e ekleyin

**Hata: Veriler sayfa yenilenince kayboluyor**
- Çözüm: localStorage'ı temizleyin, Supabase'den veri çekmesini bekleyin
  ```javascript
  localStorage.clear(); // Dikkat: Bu tüm local verileri siler
  ```

### 6. Debug Modu

Tarayıcı Console'da debug modunu açın:

```javascript
localStorage.setItem('debug_mode', 'true');
```

Bu, tüm Supabase çağrılarını ve yanıtlarını console'da gösterir.
