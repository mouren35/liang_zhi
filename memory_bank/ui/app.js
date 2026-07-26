"use strict";

const asset = (name) => `./assets/${name}`;

const foods = [
  { id: "rice", name: "大米", qty: "5 kg", date: "2025-10-30", type: "干货", image: "rice.png" },
  { id: "eggs", name: "鸡蛋", qty: "12 枚", date: "2025-06-03", type: "鲜货", image: "eggs.png" },
  { id: "milk", name: "牛奶", qty: "1 L", date: "2025-05-28", type: "鲜货", image: "milk.png", danger: true },
  { id: "flour", name: "面粉", qty: "2.5 kg", date: "2025-07-15", type: "干货", image: "flour.png" },
  { id: "lettuce", name: "生菜", qty: "1 棵", date: "2025-05-25", type: "鲜货", image: "lettuce.png" },
  { id: "apples", name: "苹果", qty: "4 个", date: "2025-05-27", type: "鲜货", image: "apples.png" },
  { id: "butter", name: "黄油", qty: "1 块", date: "2025-07-22", type: "鲜货", image: "butter.png" },
  { id: "bread", name: "面包", qty: "4 片", date: "2025-06-01", type: "鲜货", image: "bread.png" },
  { id: "oats", name: "燕麦", qty: "1 袋", date: "2025-10-18", type: "干货", image: "oats.png" },
  { id: "yogurt", name: "酸奶", qty: "1 杯", date: "2025-05-18", type: "鲜货", image: "yogurt.png" },
];

const recipes = [
  {
    name: "奶香烤吐司",
    image: "recipe-toast.png",
    ingredients: ["牛奶", "面包", "黄油"],
  },
  {
    name: "牛奶燕麦杯",
    image: "recipe-oats.png",
    ingredients: ["牛奶", "燕麦", "水果"],
  },
  {
    name: "奶油蘑菇浓汤",
    image: "recipe-soup.png",
    ingredients: ["牛奶", "蘑菇", "面粉"],
  },
];

const icons = {
  home: "home",
  expirations: "alarm",
  scan: "scan",
  foods: "grid",
  mine: "user",
};

const routes = {
  "#/home": renderHome,
  "#/expirations": renderExpirations,
  "#/scan": renderScan,
  "#/foods": renderFoods,
  "#/food/milk": renderMilkDetail,
};

const routeTitles = {
  "#/home": "粮知",
  "#/expirations": "到期提醒",
  "#/scan": "扫码添加",
  "#/foods": "全部食物",
  "#/food/milk": "食物详情",
};

function icon(name, className = "") {
  return `<svg class="icon ${className}" aria-hidden="true"><use href="#i-${name}"></use></svg>`;
}

function statusBar() {
  return `
    <div class="status-bar" aria-label="状态栏">
      <span>9:41</span>
      <span class="status-icons" aria-hidden="true">
        <span class="signal"><i></i><i></i><i></i><i></i></span>
        <span class="wifi"></span>
        <span class="battery"></span>
      </span>
    </div>
  `;
}

function topbar(title, options = {}) {
  const { home = false, back = true, action = "" } = options;
  if (home) {
    return `
      <header class="topbar home-topbar">
        <h1 class="topbar-title">${title}</h1>
        <button class="icon-button demo-button" type="button" aria-label="通知">${icon("bell")}</button>
      </header>
    `;
  }

  return `
    <header class="topbar">
      ${
        back
          ? `<button class="icon-button" type="button" data-back aria-label="返回">${icon("arrow-left")}</button>`
          : "<span></span>"
      }
      <h1 class="topbar-title">${title}</h1>
      ${action || "<span></span>"}
    </header>
  `;
}

function bottomNav(active) {
  const items = [
    ["home", "首页", "#/home"],
    ["expirations", "到期提醒", "#/expirations"],
    ["scan", "扫码添加", "#/scan"],
    ["foods", "全部食物", "#/foods"],
    ["mine", "我的", ""],
  ];

  return `
    <nav class="bottom-nav" aria-label="主导航">
      ${items
        .map(([key, label, route]) => {
          if (!route) {
            return `
              <button class="nav-item demo-button" type="button" aria-disabled="true">
                ${icon(icons[key])}
                <span>${label}</span>
              </button>
            `;
          }
          return `
              <a class="nav-item ${active === key ? "active" : ""}" href="${route}" data-route="${route}">
                ${icon(icons[key])}
                <span>${label}</span>
              </a>
            `;
        })
        .join("")}
    </nav>
  `;
}

function renderHome() {
  const stockRows = foods.slice(0, 4).map(stockRow).join("");
  return `
    <section class="screen has-nav route-enter" data-screen="home">
      ${statusBar()}
      ${topbar("粮知", { home: true })}
      <div class="page-content">
        <div class="chips" aria-label="食物分类">
          <button class="chip active demo-button" type="button">全部</button>
          <button class="chip demo-button" type="button">干货</button>
          <button class="chip demo-button" type="button">鲜货</button>
          <button class="chip demo-button" type="button">烘焙原料</button>
          <button class="chip outline demo-button" type="button">${icon("plus")}添加分类</button>
        </div>

        <button class="expiry-hero demo-button" type="button" data-route="#/expirations">
          <span class="expiry-alert-icon">!</span>
          <span>
            <strong>15<small>天内到期</small> 3<small>项</small></strong>
            <p>请尽快食用，避免浪费</p>
          </span>
          ${icon("chevron-right")}
        </button>

        <div class="section-title-row">
          <h2 class="section-title">库存概览</h2>
        </div>
        <div class="overview-grid">
          ${overviewCard("package", "12", "食物种类", "#3f854c")}
          ${overviewCard("bag", "36", "库存总数", "#1682ff")}
          ${overviewCard("clock", "3", "临近到期", "#f0a100")}
          ${overviewCard("alert", "1", "已过期", "#f02d23")}
        </div>

        <div class="section-title-row">
          <h2 class="section-title">库存清单</h2>
          <span class="section-meta">按到期日 ↑</span>
        </div>
        <div class="stock-list">${stockRows}</div>
      </div>
      <button class="floating-add demo-button" type="button" data-route="#/scan" aria-label="添加食物">
        ${icon("plus")}
      </button>
    </section>
    ${bottomNav("home")}
  `;
}

function overviewCard(iconName, count, label, color) {
  return `
    <article class="overview-card" style="--metric:${color}">
      ${icon(iconName)}
      <strong>${count}</strong>
      <span>${label}</span>
    </article>
  `;
}

function stockRow(food) {
  const detailRoute = food.id === "milk" ? `data-route="#/food/milk"` : "";
  return `
    <article class="stock-row" ${detailRoute} tabindex="0">
      <img class="stock-thumb" src="${asset(food.image)}" alt="${food.name}" />
      <strong class="stock-name">${food.name}</strong>
      <span class="stock-qty">${food.qty}</span>
      <time class="stock-date ${food.danger ? "danger" : ""}">${food.date}</time>
      <span class="tag">${food.type}</span>
      ${icon("chevron-right")}
    </article>
  `;
}

function renderExpirations() {
  const expiring = [
    { ...foods[2], remaining: "还剩 5 天" },
    { ...foods[4], remaining: "还剩 2 天" },
    { ...foods[5], remaining: "还剩 4 天" },
  ];
  const expired = [{ ...foods[9], remaining: "已过期 1 天" }];

  return `
    <section class="screen no-nav expiry-page route-enter" data-screen="expirations">
      ${statusBar()}
      ${topbar("到期提醒", {
        action: `<button class="icon-button demo-button" type="button" aria-label="设置">${icon("settings")}</button>`,
      })}
      <div class="page-content">
        <p class="group-label">临近到期（15天内）</p>
        ${expiryGroup(expiring, "3", "alarm")}
        <p class="group-label">已过期</p>
        ${expiryGroup(expired, "1", "alert")}
        <aside class="tip-card">
          ${icon("lightbulb")}
          <div>
            <strong>小贴士</strong>
            <p>建议优先处理临近到期食物，合理规划饮食，避免浪费。</p>
          </div>
        </aside>
      </div>
    </section>
  `;
}

function expiryGroup(items, count, watermarkIcon) {
  return `
    <section class="expiry-group">
      <header class="expiry-group-head">
        <span class="expiry-count">${count}<small>项</small></span>
        <span class="expiry-watermark">${icon(watermarkIcon)}</span>
      </header>
      <div class="expiry-items">
        ${items
          .map(
            (item) => `
              <article class="expiry-item">
                <img src="${asset(item.image)}" alt="${item.name}" />
                <div>
                  <h3>${item.name}</h3>
                  <p>${item.qty} · ${item.type}</p>
                </div>
                <div class="expiry-item-time">
                  <strong>${item.remaining}</strong>
                  <span>${item.date}</span>
                </div>
              </article>
            `,
          )
          .join("")}
      </div>
    </section>
  `;
}

function renderScan() {
  return `
    <section class="screen no-nav route-enter" data-screen="scan">
      ${statusBar()}
      ${topbar("扫码添加")}
      <p class="scan-caption">将商品条形码放入框内</p>
      <div class="scanner" aria-label="条形码识别区域">
        <i class="scanner-corner tl"></i><i class="scanner-corner tr"></i>
        <i class="scanner-corner bl"></i><i class="scanner-corner br"></i>
        <div class="barcode-card">${barcodeSvg()}</div>
        <span class="scan-line"></span>
      </div>

      <article class="detected-card">
        <img src="${asset("milk.png")}" alt="牛奶" />
        <div>
          <h2>牛奶 1L</h2>
          <p>鲜牛奶</p>
          <span class="detect-success">${icon("check-circle")}识别成功</span>
        </div>
      </article>

      <div class="scan-form">
        <div class="form-row">
          <strong>数量</strong>
          <span class="form-value counter">
            <button class="counter-button demo-button" type="button" aria-label="减少">${icon("minus")}</button>
            <b>1</b>
            <button class="counter-button demo-button" type="button" aria-label="增加">${icon("plus")}</button>
            瓶
          </span>
        </div>
        <div class="form-row">
          <strong>到期日期</strong>
          <span class="form-value">2025-05-28 ${icon("calendar")}</span>
        </div>
        <div class="form-row">
          <strong>分类</strong>
          <span class="form-value">鲜货 ${icon("chevron-down")}</span>
        </div>
        <div class="form-row">
          <strong>存放位置（可选）</strong>
          <span class="form-value">冷藏室 ${icon("chevron-down")}</span>
        </div>
        <div class="form-row">
          <strong>备注（可选）</strong>
          <span class="form-value">例如：品牌、规格等</span>
        </div>
      </div>
      <button class="scan-submit demo-button" type="button">加入库存</button>
    </section>
  `;
}

function barcodeSvg() {
  const bars = [
    [8, 2], [13, 4], [20, 2], [25, 6], [34, 2], [40, 3], [47, 6], [56, 2],
    [61, 4], [69, 2], [75, 7], [85, 3], [92, 2], [97, 5], [105, 2], [112, 6],
    [121, 3], [127, 2], [133, 5], [142, 2], [148, 7], [158, 3], [164, 2],
  ];
  return `
    <svg viewBox="0 0 180 78" role="img" aria-label="条形码 6901234567893">
      <g fill="#171817">
        ${bars.map(([x, width], i) => `<rect x="${x}" y="2" width="${width}" height="${i % 4 === 0 ? 48 : 43}" />`).join("")}
      </g>
      <text x="90" y="70" text-anchor="middle" font-size="16" letter-spacing="2.3" fill="#171817">6 901234 567893</text>
    </svg>
  `;
}

function renderFoods() {
  return `
    <section class="screen has-nav route-enter" data-screen="foods">
      ${statusBar()}
      ${topbar("全部食物", {
        action: `<button class="icon-button demo-button" type="button" aria-label="搜索">${icon("search")}</button>`,
      })}
      <div class="page-content">
        <p class="foods-note">${icon("check-circle")}仅显示有效食物（未过期）</p>
        <div class="food-grid">
          ${foods
            .map(
              (food) => `
                <button
                  class="food-card"
                  type="button"
                  ${food.id === "milk" ? `data-route="#/food/milk"` : ""}
                  aria-label="${food.name}"
                >
                  <img src="${asset(food.image)}" alt="" />
                  <strong>${food.name}</strong>
                </button>
              `,
            )
            .join("")}
        </div>
      </div>
    </section>
    ${bottomNav("foods")}
  `;
}

function renderMilkDetail() {
  return `
    <section class="screen no-nav detail-page route-enter" data-screen="milk-detail">
      ${statusBar()}
      ${topbar("食物详情")}
      <div class="page-content">
        <section class="food-detail-hero">
          <img src="${asset("milk-detail.png")}" alt="玻璃瓶装牛奶" />
          <div>
            <div class="food-detail-title">
              <h1>牛奶</h1>
              <span class="tag">鲜货</span>
            </div>
            <dl class="detail-facts">
              <div class="detail-fact"><dt>数量</dt><dd>1 L（1 瓶）</dd></div>
              <div class="detail-fact"><dt>到期日期</dt><dd>2025-05-28</dd></div>
              <div class="detail-fact"><dt>存放位置</dt><dd>冷藏室</dd></div>
              <div class="detail-fact"><dt>备注</dt><dd>–</dd></div>
            </dl>
          </div>
        </section>

        <section class="recipes">
          <h2>关联食谱</h2>
          <p>与牛奶相关的推荐食谱</p>
          ${recipes.map(recipeCard).join("")}
        </section>

        <div class="detail-actions">
          <button class="outline-action demo-button" type="button">${icon("edit")}编辑信息</button>
          <button class="outline-action danger demo-button" type="button">${icon("trash")}移除</button>
        </div>
      </div>
    </section>
  `;
}

function recipeCard(recipe) {
  return `
    <article class="recipe-card">
      <img src="${asset(recipe.image)}" alt="${recipe.name}" />
      <div>
        <div class="recipe-title-row">
          <h3>${recipe.name}</h3>
          <span class="recipe-match">库存可匹配</span>
        </div>
        <p>主食材：牛奶</p>
        <div class="ingredient-tags">${recipe.ingredients.map((item) => `<span>${item}</span>`).join("")}</div>
      </div>
      ${icon("chevron-right")}
    </article>
  `;
}

function normalizeRoute() {
  const current = window.location.hash || "#/home";
  if (routes[current]) return current;
  window.history.replaceState(null, "", "#/home");
  return "#/home";
}

function render() {
  const route = normalizeRoute();
  const app = document.querySelector("#app");
  app.innerHTML = routes[route]();
  document.title = `${routeTitles[route]} · 粮知`;
  app.querySelector(".screen")?.scrollTo(0, 0);
}

function navigate(route) {
  if (!routes[route]) return;
  if (window.location.hash === route) {
    render();
    return;
  }
  window.location.hash = route;
}

function goBack() {
  if (window.history.length > 1) {
    window.history.back();
  } else {
    navigate("#/home");
  }
}

document.addEventListener("click", (event) => {
  const routeTarget = event.target.closest("[data-route]");
  if (routeTarget) {
    event.preventDefault();
    navigate(routeTarget.dataset.route);
    return;
  }

  if (event.target.closest("[data-back]")) {
    goBack();
  }
});

document.addEventListener("keydown", (event) => {
  if (event.key !== "Enter" && event.key !== " ") return;
  const routeTarget = event.target.closest("[data-route]");
  if (routeTarget && routeTarget.tagName !== "A" && routeTarget.tagName !== "BUTTON") {
    event.preventDefault();
    navigate(routeTarget.dataset.route);
  }
});

window.addEventListener("hashchange", render);
window.addEventListener("DOMContentLoaded", render);
