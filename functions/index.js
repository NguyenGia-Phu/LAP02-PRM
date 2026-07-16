/* eslint-disable require-jsdoc, linebreak-style, quote-props */
const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

setGlobalOptions({maxInstances: 10});
admin.initializeApp();

const supportedTypes = ["trending_topic", "highly_cited", "research_update"];
const researchTopics = [
  "machine learning",
  "artificial intelligence",
  "cybersecurity",
  "internet of things",
  "blockchain",
  "cloud computing",
  "data science",
  "computer vision",
  "natural language processing",
  "software engineering",
];

function getHourlyNotificationSelection(now = new Date()) {
  const hourNumber = Math.floor(now.getTime() / (60 * 60 * 1000));
  return {
    topic: researchTopics[hourNumber % researchTopics.length],
    type: supportedTypes[hourNumber % supportedTypes.length],
  };
}

async function fetchTrendingPublication(topic) {
  const selectedTopic = topic || "machine learning";
  const requestUrl = new URL("https://api.openalex.org/works");
  requestUrl.searchParams.set("search", selectedTopic);
  requestUrl.searchParams.set("sort", "cited_by_count:desc");
  requestUrl.searchParams.set("per-page", "1");
  requestUrl.searchParams.set("mailto", "ndanthanh161@gmail.com");

  let lastError;
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    try {
      const response = await fetch(requestUrl);
      if (!response.ok) {
        throw new Error(`OpenAlex request failed with ${response.status}`);
      }

      const data = await response.json();
      return data.results && data.results[0] ? data.results[0] : null;
    } catch (error) {
      lastError = error;
      logger.warn("OpenAlex notification lookup failed", {
        topic: selectedTopic,
        attempt,
        error: error.message,
      });
      if (attempt < 3) {
        await new Promise((resolve) => setTimeout(resolve, attempt * 500));
      }
    }
  }
  throw lastError;
}

function normalizeType(type) {
  if (supportedTypes.includes(type)) {
    return type;
  }
  return "trending_topic";
}

function buildNotificationPayload(type, topic, publication) {
  const publicationTitle = publication.title || "A research publication";
  const citations = publication.cited_by_count || 0;

  if (type === "highly_cited") {
    return {
      title: "Highly cited publication alert",
      body: `${publicationTitle} has ${citations} citations in ${topic}.`,
    };
  }

  if (type === "research_update") {
    return {
      title: "Research trend update",
      body: `Latest ${topic} research update: ${publicationTitle}.`,
    };
  }

  return {
    title: "New trending research topic",
    body: `${publicationTitle} is trending in ${topic}.`,
  };
}

async function sendTrendingTopicNotification(topic, type) {
  const selectedTopic = topic || "machine learning";
  const selectedType = normalizeType(type || "trending_topic");
  let publication;
  try {
    publication = await fetchTrendingPublication(selectedTopic);
  } catch (error) {
    logger.warn("Using topic-only notification fallback", {
      topic: selectedTopic,
      error: error.message,
    });
  }

  const isTopicOnly = !publication;
  publication = publication || {
    title: `Latest ${selectedTopic} research`,
    cited_by_count: 0,
    publication_year: new Date().getUTCFullYear(),
  };

  const publicationTitle = publication.title || "Trending research publication";
  const notification = isTopicOnly ? {
    title: `Research update: ${selectedTopic}`,
    body: `Tap to explore the latest publications about ${selectedTopic}.`,
  } : buildNotificationPayload(
      selectedType,
      selectedTopic,
      publication,
  );

  await admin.messaging().send({
    topic: "trend_updates",
    notification,
    data: {
      type: selectedType,
      topic: selectedTopic,
      publicationTitle,
      publicationId: String(publication.id || ""),
      publicationYear: String(publication.publication_year || 0),
      citations: String(publication.cited_by_count || 0),
    },
  });

  logger.info("Trending notification sent", {
    topic: selectedTopic,
    type: selectedType,
    title: publicationTitle,
  });
  return {
    sent: true,
    topic: selectedTopic,
    type: selectedType,
    title: publicationTitle,
    notification,
  };
}

exports.sendTrendingTopicNotificationNow = onRequest(
    async (request, response) => {
      try {
        const topic = request.query.topic || "machine learning";
        const type = request.query.type || "trending_topic";
        const result = await sendTrendingTopicNotification(
            String(topic),
            String(type),
        );
        response.json(result);
      } catch (error) {
        logger.error("Failed to send trending notification", error);
        response.status(500).json({error: error.message});
      }
    },
);

exports.sendDailyTrendingTopicNotification = onSchedule(
    "every 60 minutes",
    async () => {
      const selection = getHourlyNotificationSelection();
      await sendTrendingTopicNotification(selection.topic, selection.type);
    },
);
