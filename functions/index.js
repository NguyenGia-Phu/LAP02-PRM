/* eslint-disable require-jsdoc, linebreak-style, quote-props */
const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

setGlobalOptions({maxInstances: 10});
admin.initializeApp();

const supportedTypes = ["trending_topic", "highly_cited", "research_update"];

async function fetchTrendingPublication(topic) {
  const selectedTopic = topic || "machine learning";
  const params = new URLSearchParams({
    search: selectedTopic,
    sort: "cited_by_count:desc",
    "per-page": "1",
  });
  const response = await fetch(`https://api.openalex.org/works?${params}`);

  if (!response.ok) {
    throw new Error(`OpenAlex request failed with ${response.status}`);
  }

  const data = await response.json();
  if (!data.results || data.results.length === 0) {
    return null;
  }
  return data.results[0];
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
  const publication = await fetchTrendingPublication(selectedTopic);

  if (!publication) {
    logger.warn("No trending publication found", {topic: selectedTopic});
    return {sent: false, topic: selectedTopic, type: selectedType};
  }

  const publicationTitle = publication.title || "Trending research publication";
  const notification = buildNotificationPayload(
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
    "every 24 hours",
    async () => {
      await sendTrendingTopicNotification("machine learning", "trending_topic");
    },
);
