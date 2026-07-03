import React from 'react';

interface LogoProps {
  className?: string;
  height?: number | string;
}

export const FlowLogoDefs: React.FC = () => (
  <svg className="absolute w-0 h-0" aria-hidden="true">
    <defs>
      {/* Metallic Silver/Chrome Gradient for the FLOW text */}
      <linearGradient id="metallic-silver" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#ffffff" />
        <stop offset="20%" stopColor="#e2e8f0" />
        <stop offset="40%" stopColor="#94a3b8" />
        <stop offset="50%" stopColor="#cbd5e1" />
        <stop offset="65%" stopColor="#475569" />
        <stop offset="85%" stopColor="#cbd5e1" />
        <stop offset="100%" stopColor="#334155" />
      </linearGradient>

      {/* Vibrant Red/Crimson Gradient for the Checkmark */}
      <linearGradient id="crimson-check" x1="0%" y1="100%" x2="100%" y2="0%">
        <stop offset="0%" stopColor="#991b1b" />
        <stop offset="30%" stopColor="#dc2626" />
        <stop offset="70%" stopColor="#ef4444" />
        <stop offset="100%" stopColor="#fca5a5" />
      </linearGradient>

      {/* Glowing Neon Red Filter */}
      <filter id="neon-red-glow" x="-20%" y="-20%" width="140%" height="140%">
        <feGaussianBlur stdDeviation="3" result="blur" />
        <feMerge>
          <feMergeNode in="blur" />
          <feMergeNode in="blur" />
          <feMergeNode in="SourceGraphic" />
        </feMerge>
      </filter>

      {/* Purple Glowing Thread Loop */}
      <linearGradient id="purple-thread" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#3b0764" />
        <stop offset="30%" stopColor="#7e22ce" />
        <stop offset="70%" stopColor="#a855f7" />
        <stop offset="100%" stopColor="#1e1b4b" />
      </linearGradient>

      {/* Background radial gradient matching the logo mockup */}
      <radialGradient id="bg-radial" cx="50%" cy="50%" r="70%">
        <stop offset="0%" stopColor="#251c31" />
        <stop offset="50%" stopColor="#161021" />
        <stop offset="100%" stopColor="#0a0711" />
      </radialGradient>
    </defs>
  </svg>
);

// Helper for sparkle stars
const SparkleStar: React.FC<{ cx: number; cy: number; scale?: number; opacity?: number }> = ({ cx, cy, scale = 1, opacity = 1 }) => (
  <path
    d={`M ${cx - 10 * scale} ${cy} Q ${cx} ${cy} ${cx} ${cy - 10 * scale} Q ${cx} ${cy} ${cx + 10 * scale} ${cy} Q ${cx} ${cy} ${cx} ${cy + 10 * scale} Q ${cx} ${cy} ${cx - 10 * scale} ${cy} Z`}
    fill="#ffffff"
    opacity={opacity}
    className="animate-pulse"
    style={{ transformOrigin: `${cx}px ${cy}px`, animationDuration: `${2 + Math.random() * 2}s` }}
  />
);

/**
 * FlowLogoWide: High-fidelity 16:9 or custom banner mirroring the user's uploaded image.
 */
export const FlowLogoWide: React.FC<LogoProps & { showSubtitle?: boolean }> = ({ 
  className = '', 
  height = '100%', 
  showSubtitle = true 
}) => {
  return (
    <div 
      className={`relative rounded-2xl overflow-hidden border border-slate-800 shadow-2xl flex flex-col items-center justify-center ${className}`}
      style={{ 
        background: 'url(#bg-radial), radial-gradient(circle at center, #231930 0%, #0d0818 100%)',
        height: height
      }}
    >
      <FlowLogoDefs />
      
      {/* Background Grid Lines Overlay */}
      <div className="absolute inset-0 opacity-15 pointer-events-none mix-blend-overlay">
        <svg width="100%" height="100%">
          <defs>
            <pattern id="grid" width="30" height="30" patternUnits="userSpaceOnUse">
              <path d="M 30 0 L 0 0 0 30" fill="none" stroke="#a855f7" strokeWidth="0.5" />
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#grid)" />
        </svg>
      </div>

      {/* Sparkles */}
      <svg className="absolute inset-0 w-full h-full pointer-events-none" viewBox="0 0 500 250">
        <SparkleStar cx={60} cy={50} scale={0.7} opacity={0.6} />
        <SparkleStar cx={440} cy={160} scale={0.6} opacity={0.5} />
        <SparkleStar cx={410} cy={70} scale={0.4} opacity={0.4} />
        <SparkleStar cx={80} cy={190} scale={0.5} opacity={0.4} />
      </svg>

      {/* Main Logo Graphic Container */}
      <div className="z-10 flex flex-col items-center justify-center p-6 w-full max-w-[480px]">
        <svg 
          viewBox="0 0 460 160" 
          width="100%" 
          height="100%"
          className="drop-shadow-[0_8px_24px_rgba(0,0,0,0.6)]"
        >
          {/* BACKGROUND DETAILS: Subtle flare/glow behind letters */}
          <circle cx="230" cy="75" r="45" fill="#ef4444" opacity="0.08" filter="blur(15px)" />
          <circle cx="230" cy="75" r="60" fill="#a855f7" opacity="0.05" filter="blur(20px)" />

          {/* VIOLET/PURPLE INFINITY LOOP THREAD */}
          {/* Back parts of the loop, rendered behind letters */}
          <path
            d="M 60 75 C 60 20, 200 40, 220 75 C 235 105, 340 100, 370 75 C 390 55, 360 40, 330 75"
            fill="none"
            stroke="url(#purple-thread)"
            strokeWidth="7"
            strokeLinecap="round"
            opacity="0.85"
          />

          {/* THE "FLOW" TEXT */}
          <g className="font-sans font-black tracking-tight" style={{ fontFamily: '"Outfit", "Inter", sans-serif' }}>
            {/* F */}
            <text x="50" y="105" fontSize="100" fill="url(#metallic-silver)" stroke="#1e293b" strokeWidth="2.5" strokeLinejoin="miter">
              F
            </text>
            {/* L */}
            <text x="110" y="105" fontSize="100" fill="url(#metallic-silver)" stroke="#1e293b" strokeWidth="2.5" strokeLinejoin="miter">
              L
            </text>
            {/* O */}
            {/* Styled with slightly more width to let the checkmark fit nicely inside */}
            <text x="165" y="105" fontSize="100" fill="url(#metallic-silver)" stroke="#1e293b" strokeWidth="2.5" strokeLinejoin="miter">
              O
            </text>
            {/* W */}
            <text x="255" y="105" fontSize="100" fill="url(#metallic-silver)" stroke="#1e293b" strokeWidth="2.5" strokeLinejoin="miter">
              W
            </text>
          </g>

          {/* FOREGROUND PARTS OF THE INFINITY LOOP */}
          <path
            d="M 220 75 C 240 110, 360 110, 390 75 C 410 50, 380 40, 350 75 C 330 100, 200 30, 110 75"
            fill="none"
            stroke="url(#purple-thread)"
            strokeWidth="7"
            strokeLinecap="round"
            opacity="0.9"
          />

          {/* RED/CRIMSON HARPOON/SPEAR END POINT */}
          {/* This points to the right and connects the thread to a neat spear tip */}
          <g transform="translate(390, 75) rotate(-5)">
            <line x1="-15" y1="0" x2="15" y2="0" stroke="#7e22ce" strokeWidth="6" strokeLinecap="round" />
            <circle cx="15" cy="0" r="5" fill="#991b1b" stroke="#ffffff" strokeWidth="1" />
            <path
              d="M 18 -10 L 40 0 L 18 10 L 23 0 Z"
              fill="url(#crimson-check)"
              stroke="#500707"
              strokeWidth="1.5"
              filter="url(#neon-red-glow)"
            />
          </g>

          {/* GLOWING RED/CRIMSON CHECKMARK */}
          {/* This cuts dynamically through the "O" */}
          <path
            d="M 195 80 L 225 105 L 320 30"
            fill="none"
            stroke="url(#crimson-check)"
            strokeWidth="15"
            strokeLinecap="round"
            strokeLinejoin="round"
            filter="url(#neon-red-glow)"
          />
        </svg>

        {/* SUBTITLE */}
        {showSubtitle && (
          <div className="mt-2 text-center select-none">
            <span 
              className="text-xs md:text-sm font-bold tracking-[0.45em] text-white/90 uppercase"
              style={{ fontFamily: '"Space Grotesk", sans-serif' }}
            >
              TO-DO LIST APP
            </span>
          </div>
        )}
      </div>
    </div>
  );
};

/**
 * FlowLogoCompact: Lightweight vector representation of the brand, ideal for inside headers.
 */
export const FlowLogoCompact: React.FC<LogoProps> = ({ className = '', height = 24 }) => {
  return (
    <div className={`flex items-center gap-1 ${className}`} style={{ height }}>
      <FlowLogoDefs />
      <svg 
        viewBox="0 0 380 120" 
        height={height}
        className="w-auto drop-shadow-md overflow-visible"
      >
        {/* Purple Background Ring behind "O" */}
        <circle cx="195" cy="60" r="18" fill="#7e22ce" opacity="0.1" filter="blur(4px)" />

        {/* Purple thread loop back-layer */}
        <path
          d="M 50 60 C 50 15, 170 30, 190 60 C 205 85, 290 85, 310 60"
          fill="none"
          stroke="url(#purple-thread)"
          strokeWidth="5"
          strokeLinecap="round"
          opacity="0.8"
        />

        {/* Letters */}
        <g className="font-sans font-black tracking-tight" style={{ fontFamily: '"Outfit", "Inter", sans-serif' }}>
          <text x="40" y="85" fontSize="76" fill="url(#metallic-silver)" stroke="#111827" strokeWidth="1.5">F</text>
          <text x="90" y="85" fontSize="76" fill="url(#metallic-silver)" stroke="#111827" strokeWidth="1.5">L</text>
          <text x="135" y="85" fontSize="76" fill="url(#metallic-silver)" stroke="#111827" strokeWidth="1.5">O</text>
          <text x="210" y="85" fontSize="76" fill="url(#metallic-silver)" stroke="#111827" strokeWidth="1.5">W</text>
        </g>

        {/* Purple thread loop fore-layer */}
        <path
          d="M 190 60 C 205 85, 300 85, 320 60 C 335 40, 315 30, 295 60 C 275 80, 170 20, 95 60"
          fill="none"
          stroke="url(#purple-thread)"
          strokeWidth="5"
          strokeLinecap="round"
          opacity="0.85"
        />

        {/* Red Spear tip */}
        <g transform="translate(320, 60) scale(0.85) rotate(-5)">
          <line x1="-12" y1="0" x2="12" y2="0" stroke="#7e22ce" strokeWidth="5" strokeLinecap="round" />
          <circle cx="12" cy="0" r="4" fill="#991b1b" stroke="#ffffff" strokeWidth="0.8" />
          <path
            d="M 14 -8 L 32 0 L 14 8 L 18 0 Z"
            fill="url(#crimson-check)"
            stroke="#500707"
            strokeWidth="1.2"
            filter="url(#neon-red-glow)"
          />
        </g>

        {/* Glowing Crimson Checkmark */}
        <path
          d="M 160 62 L 185 82 L 260 22"
          fill="none"
          stroke="url(#crimson-check)"
          strokeWidth="11"
          strokeLinecap="round"
          strokeLinejoin="round"
          filter="url(#neon-red-glow)"
        />
      </svg>
    </div>
  );
};

/**
 * FlowAppIcon: 1:1 square ratio icon perfect for launcher screens or device display grids.
 */
export const FlowAppIcon: React.FC<LogoProps & { size?: number }> = ({ className = '', size = 48 }) => {
  return (
    <div 
      className={`rounded-xl flex items-center justify-center overflow-hidden border border-slate-800 shadow-lg shrink-0 ${className}`}
      style={{ 
        background: 'radial-gradient(circle at center, #2d1f3d 0%, #0d091a 100%)',
        width: size,
        height: size
      }}
    >
      <FlowLogoDefs />
      <svg 
        viewBox="0 0 120 120" 
        width="100%" 
        height="100%"
        className="overflow-visible"
      >
        {/* Glow */}
        <circle cx="60" cy="60" r="24" fill="#ef4444" opacity="0.15" filter="blur(8px)" />
        <circle cx="60" cy="60" r="30" fill="#a855f7" opacity="0.1" filter="blur(12px)" />

        {/* Ambient background lines */}
        <line x1="20" y1="0" x2="20" y2="120" stroke="#3b2d54" strokeWidth="0.5" />
        <line x1="100" y1="0" x2="100" y2="120" stroke="#3b2d54" strokeWidth="0.5" />
        <line x1="0" y1="20" x2="120" y2="20" stroke="#3b2d54" strokeWidth="0.5" />
        <line x1="0" y1="100" x2="120" y2="100" stroke="#3b2d54" strokeWidth="0.5" />

        {/* Sparkles */}
        <path d="M 95 25 Q 100 25 100 20 Q 100 25 105 25 Q 100 25 100 30 Q 100 25 95 25 Z" fill="#ffffff" opacity="0.6" />
        <path d="M 15 85 Q 20 85 20 80 Q 20 85 25 85 Q 20 85 20 90 Q 20 85 15 85 Z" fill="#ffffff" opacity="0.5" />

        {/* Small "F" letter in silver background */}
        <text x="25" y="78" fontSize="42" fill="url(#metallic-silver)" fontWeight="900" fontFamily='"Outfit", sans-serif' opacity="0.25">F</text>

        {/* Infinity loop loop back layer */}
        <path
          d="M 30 60 C 30 30, 90 30, 90 60"
          fill="none"
          stroke="url(#purple-thread)"
          strokeWidth="4.5"
          strokeLinecap="round"
          opacity="0.8"
        />

        {/* Infinity loop fore layer */}
        <path
          d="M 90 60 C 90 90, 30 90, 30 60"
          fill="none"
          stroke="url(#purple-thread)"
          strokeWidth="4.5"
          strokeLinecap="round"
          opacity="0.9"
        />

        {/* Red Spear tip rotated nicely */}
        <g transform="translate(90, 60) scale(0.65) rotate(45)">
          <path
            d="M 0 -10 L 20 0 L 0 10 L 4 0 Z"
            fill="url(#crimson-check)"
            stroke="#500707"
            strokeWidth="1"
            filter="url(#neon-red-glow)"
          />
        </g>

        {/* Glowing Red Checkmark as the main hero symbol of the icon */}
        <path
          d="M 40 60 L 58 78 L 92 34"
          fill="none"
          stroke="url(#crimson-check)"
          strokeWidth="9"
          strokeLinecap="round"
          strokeLinejoin="round"
          filter="url(#neon-red-glow)"
        />
      </svg>
    </div>
  );
};
