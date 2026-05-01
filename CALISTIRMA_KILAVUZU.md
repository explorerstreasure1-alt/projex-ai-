# Çalıştırma Kılavuzu

## 1. Supabase Şema Dosyasını Çalıştırma

### Adım 1: Supabase Dashboard'a Giriş
1. https://app.supabase.com adresine git
2. Projeni seç (PROJEX AI)
3. Sol menüden **"SQL Editor"** seçeneğine tıkla

### Adım 2: SQL Dosyasını Yükle
1. SQL Editor'da **"New Query"** butonuna tıkla
2. `supabase_schema_meeting_fixes.sql` dosyasının içeriğini kopyala
3. Editor'e yapıştır
4. **"Run"** butonuna tıkla

### Adım 3: Başarılı Olduğunu Kontrol Et
Çıktıda şu mesajları görmelisin:
```
Success. No rows returned
```

Veya tablo oluşturuldu mesajları.

---

## 2. Lokal Test (Bilgisayarında)

### Terminal/Komut Satırı Aç
```bash
# Proje klasörüne git
cd "c:\Users\explo\OneDrive\Desktop\güncel5\güncel1"

# Node.js bağımlılıkları yükle (eğer yoksa)
npm install

# Sunucuyu başlat
node server.js
```

### Tarayıcıda Aç
- http://localhost:3000 adresine git
- Test et, kaydet, sayfa yenile kontrolü yap

---

## 3. Vercel'e Deploy Etme

### Adım 1: Vercel CLI Kurulumu (Eğer yoksa)
```bash
npm install -g vercel
```

### Adım 2: Login Ol
```bash
vercel login
```

### Adım 3: Deploy Et
```bash
# Proje klasöründe
cd "c:\Users\explo\OneDrive\Desktop\güncel5\güncel1"

# Deploy
vercel --prod
```

### Adım 4: Environment Variables Ekle
Vercel Dashboard'da:
1. Proje seç → **"Settings"** → **"Environment Variables"**
2. Şu değişkenleri ekle:

| Name | Value |
|------|-------|
| `SUPABASE_URL` | `https://dbwhzmpfgfgemifiuhrp.supabase.co` |
| `SUPABASE_ANON_KEY` | `sb_publishable_aFj8bK_5bV-6CuDlpJDLMw_UmJPDXY1` |

3. **"Save"** butonuna tıkla

---

## 4. Supabase Storage Bucket Oluşturma

Ses kayıtları için bucket gerekli:

1. Supabase Dashboard → **"Storage"** → **"New Bucket"**
2. Bucket adı: `voice-recordings`
3. **"Public bucket"** seçeneğini işaretle (dosyalar herkese açık olacaksa)
4. **"Create bucket"**

### Storage RLS Politikaları
Storage sekmesinde **"Policies"** → **"New Policy"**:

```sql
-- Upload policy
CREATE POLICY "Users can upload own recordings"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'voice-recordings' AND auth.uid()::text = (storage.foldername(name))[1]);

-- View policy  
CREATE POLICY "Users can view own recordings"
ON storage.objects FOR SELECT
USING (bucket_id = 'voice-recordings' AND auth.uid()::text = (storage.foldername(name))[1]);
```

---

## 5. Hata Kontrolü

### Tarayıcı Console Kontrolü
F12 tuşuna bas → **"Console"** sekmesi:

```javascript
// Supabase bağlantı testi
const { data, error } = await supabaseClient.from('projects').select('count');
console.log(data, error);
```

### Network Tab Kontrolü
F12 → **"Network"** sekmesi:
- Supabase isteklerini görebilirsin (200 = başarılı, 4xx/5xx = hata)

---

## Özet Komutlar

```bash
# Lokal test
cd "c:\Users\explo\OneDrive\Desktop\güncel5\güncel1"
npm install
node server.js

# Vercel deploy
vercel --prod
```

**Önemli:** Supabase şema dosyasını çalıştırmadan uygulama çalışmaz!
