import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { createClient } from "@/lib/supabase/server";
import Navbar from "@/components/Navbar";
import FullscreenButton from "@/components/FullscreenButton";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "MEALgorithm AI",
  description: "AI-powered nutrition tracking and recommendations",
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  return (
    <html lang="en">
      <body className={`${inter.className} antialiased`}>
        <FullscreenButton />
        {user && <Navbar userEmail={user.email} />}
        <main className="page-transition">
          {children}
        </main>
      </body>
    </html>
  );
}
