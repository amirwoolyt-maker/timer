"""ساخت عکس loading جدید - اژدهای SVG با کیفیت بهتر"""
from PIL import Image, ImageDraw, ImageFont
import os

OUT = '/home/z/my-project/public/loading.png'
OUT_SMALL = '/home/z/my-project/public/loading-small.png'

def create_dragon_loading(size, path):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # پس‌زمینه گرد تیره
    margin = size // 10
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=size // 5,
        fill=(15, 23, 42, 255)  # slate-900
    )
    
    cx = size // 2
    cy = size // 2 - size // 20
    
    # بدن اژدها - مار موج‌دار سبز
    body_color = (16, 185, 129, 255)  # emerald-500
    body_dark = (5, 150, 105, 255)  # emerald-600
    body_light = (52, 211, 153, 255)  # emerald-400
    
    # رسم بدن با چند خط ضخیم
    body_width = max(6, size // 30)
    
    # مار موج‌دار
    points = []
    for i in range(25):
        t = i / 24
        x = cx - size * 0.35 + t * size * 0.7
        wave = size * 0.12 * (1 - abs(2*t - 1)) * (1 if i % 2 == 0 else -1)
        y = cy + wave
        points.append((x, y))
    
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=body_color, width=body_width)
    
    # بال‌ها
    wing_color = (5, 150, 105, 200)
    wing1 = [
        (cx - size * 0.05, cy - size * 0.05),
        (cx - size * 0.25, cy - size * 0.35),
        (cx - size * 0.12, cy - size * 0.2),
        (cx, cy - size * 0.12),
    ]
    draw.polygon(wing1, fill=wing_color)
    
    wing2 = [
        (cx + size * 0.05, cy - size * 0.05),
        (cx + size * 0.2, cy - size * 0.3),
        (cx + size * 0.1, cy - size * 0.18),
        (cx + size * 0.03, cy - size * 0.1),
    ]
    draw.polygon(wing2, fill=(5, 150, 105, 180))
    
    # سر اژدها
    head_x = cx + size * 0.38
    head_y = cy - size * 0.02
    head_r = size * 0.13
    
    draw.ellipse(
        [head_x - head_r, head_y - head_r, head_x + head_r, head_y + head_r],
        fill=body_color
    )
    
    # شاخ‌ها
    horn_w = max(3, size // 40)
    horn1 = [(head_x - head_r*0.3, head_y - head_r*0.6),
             (head_x - head_r*0.6, head_y - head_r*2)]
    horn2 = [(head_x + head_r*0.3, head_y - head_r*0.6),
             (head_x + head_r*0.6, head_y - head_r*2)]
    draw.line(horn1, fill=body_dark, width=horn_w)
    draw.line(horn2, fill=body_dark, width=horn_w)
    
    # چشم سفید
    eye_r = max(3, size // 60)
    eye_x = head_x + head_r * 0.15
    eye_y = head_y - head_r * 0.1
    draw.ellipse(
        [eye_x - eye_r, eye_y - eye_r, eye_x + eye_r, eye_y + eye_r],
        fill=(255, 255, 255, 255)
    )
    
    # مردمک
    pupil_r = max(1, size // 100)
    draw.ellipse(
        [eye_x - pupil_r, eye_y - pupil_r, eye_x + pupil_r, eye_y + pupil_r],
        fill=(15, 23, 42, 255)
    )
    
    # دم با نوک
    tail_points = points[:5]
    tail_tip = (points[0][0] - size * 0.05, points[0][1] + size * 0.08)
    draw.line([points[0], tail_tip], fill=body_dark, width=body_width // 2)
    
    # پنجه‌ها
    leg_w = max(3, size // 35)
    for i, lx in enumerate([cx - size * 0.12, cx + size * 0.08]):
        leg_y = cy + size * 0.12
        draw.line([(lx, cy + size * 0.02), (lx, leg_y)], fill=body_dark, width=leg_w)
        # پنجه
        for j in range(3):
            draw.line(
                [(lx, leg_y), (lx - 4 + j * 4, leg_y + 6)],
                fill=body_dark, width=max(2, size // 50)
            )
    
    # متن "در حال بارگذاری"
    try:
        font_size = max(10, size // 14)
        font = ImageFont.truetype('/home/z/my-project/public/fonts/Vazirmatn-Medium.woff2', font_size)
    except:
        font = ImageFont.load_default()
    
    text = "در حال بارگذاری..."
    text_bbox = draw.textbbox((0, 0), text, font=font)
    text_w = text_bbox[2] - text_bbox[0]
    text_h = text_bbox[3] - text_bbox[1]
    
    draw.text(
        (size // 2 - text_w // 2, size - size // 7),
        text,
        fill=(100, 116, 139, 255),  # slate-500
        font=font
    )
    
    img.save(path, 'PNG')
    print(f'Created: {path} ({size}x{size})')

create_dragon_loading(512, OUT)
create_dragon_loading(192, OUT_SMALL)
print('Done!')
