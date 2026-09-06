// Supabase Edge Function: explain-question
// Generates an AI explanation for a wrong answer using OpenAI.
//
// Deploy: supabase functions deploy explain-question
// Set secret: supabase secrets set OPENAI_API_KEY=sk-...

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { question, correctAnswer, studentAnswer } = await req.json();

    if (!question || !correctAnswer) {
      return new Response(
        JSON.stringify({ error: "question and correctAnswer are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const apiKey = Deno.env.get("OPENAI_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "OPENAI_API_KEY not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const prompt = `You are a helpful GCSE tutor. A student got a question wrong. Explain the correct answer clearly and concisely, in a way a 15-year-old would understand. Keep it under 150 words.

Question: ${question}

Correct answer: ${correctAnswer}
${studentAnswer ? `Student's wrong answer: ${studentAnswer}` : "The student did not answer."}

Explain why the correct answer is right and why the student's answer (if any) is wrong.`;

    const aiRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
        max_tokens: 300,
        temperature: 0.7,
      }),
    });

    if (!aiRes.ok) {
      const err = await aiRes.text();
      return new Response(
        JSON.stringify({ error: `AI provider error: ${err}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const data = await aiRes.json();
    const explanation = data.choices?.[0]?.message?.content ?? "No explanation generated.";

    return new Response(
      JSON.stringify({ explanation }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
